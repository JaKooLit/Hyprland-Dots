import "root:/"
import "root:/services/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root
    required property var panelWindow
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)
    readonly property var toplevels: ToplevelManager.toplevels
    readonly property int workspacesShown: ConfigOptions.overview.numOfRows * ConfigOptions.overview.numOfCols
    readonly property int workspaceGroup: Math.floor((monitor.activeWorkspace?.id - 1) / workspacesShown)
    property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor.id)
    property var windows: HyprlandData.windowList
    property var windowByAddress: HyprlandData.windowByAddress
    property var windowAddresses: HyprlandData.addresses
    property var monitorData: HyprlandData.monitors.find(m => m.id === root.monitor.id)
    property real scale: ConfigOptions.overview.scale
    property color activeBorderColor: Appearance.m3colors.m3accentSecondary

    property real workspaceImplicitWidth: Math.max(100, (monitorData?.transform % 2 === 1) ? 
        ((monitor.height - monitorData?.reserved[0] - monitorData?.reserved[2]) * root.scale / monitor.scale) :
        ((monitor.width - monitorData?.reserved[0] - monitorData?.reserved[2]) * root.scale / monitor.scale))
    property real workspaceImplicitHeight: Math.max(60, (monitorData?.transform % 2 === 1) ? 
        ((monitor.width - monitorData?.reserved[1] - monitorData?.reserved[3]) * root.scale / monitor.scale) :
        ((monitor.height - monitorData?.reserved[1] - monitorData?.reserved[3]) * root.scale / monitor.scale))

    property real workspaceNumberMargin: 80
    property real workspaceNumberSize: (ConfigOptions.overview.workspaceNumberSize > 0) 
        ? ConfigOptions.overview.workspaceNumberSize 
        : Math.min(workspaceImplicitHeight, workspaceImplicitWidth) * monitor.scale
    property int workspaceZ: 0
    property int windowZ: 1
    property int windowDraggingZ: 99999
    property real workspaceSpacing: 5

    property int draggingFromWorkspace: -1
    property int draggingTargetWorkspace: -1

    implicitWidth: overviewBackground.implicitWidth + Appearance.sizes.elevationMargin * 2
    implicitHeight: overviewBackground.implicitHeight + Appearance.sizes.elevationMargin * 2

    property Component windowComponent: OverviewWindow {}
    property list<OverviewWindow> windowWidgets: []

    // Shared wallpaper image - loaded once and reused
    Image {
        id: sharedWallpaper
        source: Appearance.background_image || ""
        visible: false // Hidden as it's only used as a source
        cache: true
        asynchronous: true
        smooth: true
        opacity: Appearance.workpaceTransparency // Adds slight transparency (0.0 = fully transparent, 1.0 = fully opaque)
    }

    StyledRectangularShadow {
        target: overviewBackground
    }
    Rectangle { // Background
        id: overviewBackground
        property real padding: 10
        anchors.fill: parent
        anchors.margins: Appearance.sizes.elevationMargin
        border.color : ColorUtils.transparentize(Appearance.m3colors.m3borderPrimary, 0.2)
        border.width : 2

        implicitWidth: workspaceColumnLayout.implicitWidth + padding * 2
        implicitHeight: workspaceColumnLayout.implicitHeight + padding * 2
        radius: Appearance.rounding.screenRounding * root.scale + padding
        color: Appearance.colors.colLayer0


        ColumnLayout { // Workspaces
            id: workspaceColumnLayout

            z: root.workspaceZ
            anchors.centerIn: parent
            spacing: workspaceSpacing
            Repeater {
                model: ConfigOptions.overview.numOfRows
                delegate: RowLayout {
                    id: row
                    property int rowIndex: index
                    spacing: workspaceSpacing

                    Repeater { // Workspace repeater
                        model: ConfigOptions.overview.numOfCols
                        Rectangle { // Workspace
                            id: workspace
                            property int colIndex: index
                            property int workspaceValue: root.workspaceGroup * workspacesShown + rowIndex * ConfigOptions.overview.numOfCols + colIndex + 1
                            property color defaultWorkspaceColor: Appearance.colors.colLayer1
                            property color hoveredWorkspaceColor: ColorUtils.mix(defaultWorkspaceColor, Appearance.colors.colLayer1Hover, 0.1)
                            property color hoveredBorderColor: Appearance.colors.colLayer2Hover
                            property bool hoveredWhileDragging: false
                            readonly property int padding: ConfigOptions.overview.windowPadding

                            Layout.preferredWidth: root.workspaceImplicitWidth
                            Layout.preferredHeight: root.workspaceImplicitHeight
                            Layout.minimumWidth: 100
                            Layout.minimumHeight: 60
                            
                            width: root.workspaceImplicitWidth
                            height: root.workspaceImplicitHeight
                            color: "transparent"
                            radius: Appearance.rounding.screenRounding * root.scale
                            clip: true
                            opacity: Appearance.workpaceTransparency // Adds slight transparency (0.0 = fully transparent, 1.0 = fully opaque)


                            // Efficient wallpaper using ShaderEffectSource
                            Rectangle {
                                id: wallpaperContainer
                                anchors.fill: parent
                                anchors.margins: 2 // Leave space for border
                                radius: workspace.radius - 2
                                color: workspace.defaultWorkspaceColor // Fallback color
                                clip: true
                                
                                ShaderEffectSource {
                                    id: wallpaperSource
                                    anchors.fill: parent
                                    sourceItem: sharedWallpaper
                                    visible: sharedWallpaper.status === Image.Ready
                                    smooth: true
                                    
                                    // Scale to fill while preserving aspect ratio
                                    transform: Scale {
                                        property real aspectRatio: sharedWallpaper.implicitWidth / Math.max(1, sharedWallpaper.implicitHeight)
                                        property real containerRatio: wallpaperContainer.width / Math.max(1, wallpaperContainer.height)
                                        
                                        xScale: aspectRatio > containerRatio ? 
                                            wallpaperContainer.height * aspectRatio / wallpaperContainer.width : 1
                                        yScale: aspectRatio > containerRatio ? 
                                            1 : wallpaperContainer.width / (wallpaperContainer.height * aspectRatio)
                                        
                                        origin.x: wallpaperContainer.width / 2
                                        origin.y: wallpaperContainer.height / 2
                                    }
                                }
                                
                                // Fallback when image fails to load or isn't ready
                                Rectangle {
                                    anchors.fill: parent
                                    color: workspace.defaultWorkspaceColor
                                    visible: sharedWallpaper.status !== Image.Ready
                                }
                                
                                // Optional: Add overlay for better text readability and hover effects
                                Rectangle {
                                    anchors.fill: parent
                                    color: hoveredWhileDragging ? hoveredWorkspaceColor : "black"
                                    opacity: hoveredWhileDragging ? 0.3 : 0.1
                                }
                            }

                            // Border overlay - on top of wallpaper
                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                radius: parent.radius
                                border.width: 1
                                border.color: hoveredWhileDragging ? hoveredBorderColor : ColorUtils.transparentize(Appearance.m3colors.m3borderPrimary, 0.6)
                                z: 10 // Ensure it's on top
                            }

                            StyledText {
                                // Position in top-left corner with padding
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.topMargin: 12  // Padding from top edge
                                anchors.leftMargin: 12 // Padding from left edge
                                
                                text: workspaceValue
                                font.pixelSize: root.workspaceNumberSize * root.scale
                                font.weight: Font.DemiBold
                                color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.8)
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignTop
                                z: 15 // Above border
                            }

                            MouseArea {
                                id: workspaceArea
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                z: 20 // Above all visual elements
                                onClicked: {
                                    if (root.draggingTargetWorkspace === -1) {
                                        GlobalStates.overviewOpen = false
                                        Hyprland.dispatch(`workspace ${workspaceValue}`)
                                    }
                                }
                            }

                            DropArea {
                                anchors.fill: parent
                                z: 20 // Same level as MouseArea
                                onEntered: {
                                    root.draggingTargetWorkspace = workspaceValue
                                    if (root.draggingFromWorkspace == root.draggingTargetWorkspace) return;
                                    hoveredWhileDragging = true
                                }
                                onExited: {
                                    hoveredWhileDragging = false
                                    if (root.draggingTargetWorkspace == workspaceValue) root.draggingTargetWorkspace = -1
                                }
                            }

                        }
                    }
                }
            }
        }

        Item { // Windows & focused workspace indicator
            id: windowSpace
            anchors.centerIn: parent
            implicitWidth: workspaceColumnLayout.implicitWidth
            implicitHeight: workspaceColumnLayout.implicitHeight

            Repeater { // Window repeater
                model: ScriptModel {
                    values: windowAddresses.filter((address) => {
                        var win = windowByAddress[address]
                        return (root.workspaceGroup * root.workspacesShown < win?.workspace?.id && win?.workspace?.id <= (root.workspaceGroup + 1) * root.workspacesShown)
                    })
                }
                delegate: OverviewWindow {
                    id: window
                    windowData: windowByAddress[modelData]
                    monitorData: HyprlandData.monitors.find(m => m.id === windowData?.monitor) // use monitorData of the monitor the window is on
                    scale: root.scale * (monitorData?.scale / root.monitor?.scale) // adjust window scale to the monitor where the overview is displayed
                    availableWorkspaceWidth: root.workspaceImplicitWidth
                    availableWorkspaceHeight: root.workspaceImplicitHeight

                    property bool atInitPosition: (initX == x && initY == y)
                    restrictToWorkspace: Drag.active || atInitPosition

                    property int workspaceColIndex: (windowData?.workspace.id - 1) % ConfigOptions.overview.numOfCols
                    property int workspaceRowIndex: Math.floor((windowData?.workspace.id - 1) % root.workspacesShown / ConfigOptions.overview.numOfCols)
                    xOffset: (root.workspaceImplicitWidth + workspaceSpacing) * workspaceColIndex
                    yOffset: (root.workspaceImplicitHeight + workspaceSpacing) * workspaceRowIndex

                    Timer {
                        id: updateWindowPosition
                        interval: ConfigOptions.hacks.arbitraryRaceConditionDelay
                        repeat: false
                        running: false
                        onTriggered: {
                            window.x = Math.max((windowData?.at[0] - monitorData?.reserved[0] - monitorData?.x) * root.scale, 0) + xOffset
                            window.y = Math.max((windowData?.at[1] - monitorData?.reserved[1] - monitorData?.y) * root.scale, 0) + yOffset
                        }
                    }

                    z: atInitPosition ? root.windowZ : root.windowDraggingZ
                    Drag.hotSpot.x: targetWindowWidth / 2
                    Drag.hotSpot.y: targetWindowHeight / 2
                    MouseArea {
                        id: dragArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: hovered = true
                        onExited: hovered = false
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        drag.target: parent
                        onPressed: {
                            root.draggingFromWorkspace = windowData?.workspace.id
                            window.pressed = true
                            window.Drag.active = true
                            window.Drag.source = window
                        }
                        onReleased: {
                            const targetWorkspace = root.draggingTargetWorkspace
                            window.pressed = false
                            window.Drag.active = false
                            root.draggingFromWorkspace = -1
                            if (targetWorkspace !== -1 && targetWorkspace !== windowData?.workspace.id) {
                                Hyprland.dispatch(`movetoworkspacesilent ${targetWorkspace}, address:${window.windowData?.address}`)
                                updateWindowPosition.restart()
                            }
                            else {
                                window.x = window.initX
                                window.y = window.initY
                            }
                        }
                        onClicked: (event) => {
                            if (!windowData) return;

                            if (event.button === Qt.LeftButton) {
                                GlobalStates.overviewOpen = false
                                Hyprland.dispatch(`focuswindow address:${windowData.address}`)
                                event.accepted = true
                            } else if (event.button === Qt.MiddleButton) {
                                Hyprland.dispatch(`closewindow address:${windowData.address}`)
                                event.accepted = true
                            }
                        }

                        StyledToolTip {
                            extraVisibleCondition: false
                            alternativeVisibleCondition: dragArea.containsMouse && !window.Drag.active
                            content: `${windowData.title}\n[${windowData.class}] ${windowData.xwayland ? "[XWayland] " : ""}\n`
                        }
                    }
                }
            }

            Rectangle { // Focused workspace indicator
                id: focusedWorkspaceIndicator
                property int activeWorkspaceInGroup: monitor.activeWorkspace?.id - (root.workspaceGroup * root.workspacesShown)
                property int activeWorkspaceRowIndex: Math.floor((activeWorkspaceInGroup - 1) / ConfigOptions.overview.numOfCols)
                property int activeWorkspaceColIndex: (activeWorkspaceInGroup - 1) % ConfigOptions.overview.numOfCols
                x: (root.workspaceImplicitWidth + workspaceSpacing) * activeWorkspaceColIndex
                y: (root.workspaceImplicitHeight + workspaceSpacing) * activeWorkspaceRowIndex
                z: root.windowZ
                width: Math.max(100, root.workspaceImplicitWidth)
                height: Math.max(60, root.workspaceImplicitHeight)
                color: "transparent"
                radius: Appearance.rounding.screenRounding * root.scale
                border.width: 2
                border.color: root.activeBorderColor
                visible: width > 0 && height > 0 && activeWorkspaceInGroup > 0
                Behavior on x {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on y {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }
    }
}
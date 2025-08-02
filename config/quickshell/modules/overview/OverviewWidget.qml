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

    // Robust reference monitor selection with comprehensive error handling
    property var referenceMonitor: {
        if (!HyprlandData.monitors || HyprlandData.monitors.length === 0) {
            console.warn("No monitors found, using current monitor as reference")
            return root.monitorData
        }
        
        var smallest = null
        var smallestArea = Number.MAX_VALUE
        
        for (var i = 0; i < HyprlandData.monitors.length; i++) {
            var current = HyprlandData.monitors[i]
            if (!current || current.disabled) continue
            
            // Ensure valid dimensions and scale
            var width = Math.max(current.width ?? 1920, 640)
            var height = Math.max(current.height ?? 1080, 480)
            var scale = Math.max(current.scale ?? 1, 0.1)
            var reserved0 = Math.max(current.reserved?.[0] ?? 0, 0)
            var reserved1 = Math.max(current.reserved?.[1] ?? 0, 0)
            var reserved2 = Math.max(current.reserved?.[2] ?? 0, 0)
            var reserved3 = Math.max(current.reserved?.[3] ?? 0, 0)
            
            // Calculate usable area
            var usableWidth = Math.max((width - reserved0 - reserved2) / scale, 100)
            var usableHeight = Math.max((height - reserved1 - reserved3) / scale, 60)
            var logicalArea = usableWidth * usableHeight
            
            if (logicalArea < smallestArea) {
                smallestArea = logicalArea
                smallest = current
            }
        }
        
        return smallest || root.monitorData || { width: 1920, height: 1080, scale: 1, reserved: [0, 0, 0, 0] }
    }
    
    property real referenceWidth: {
        if (!referenceMonitor) return 1920
        var width = Math.max(referenceMonitor.width ?? 1920, 640)
        var scale = Math.max(referenceMonitor.scale ?? 1, 0.1)
        var reserved0 = Math.max(referenceMonitor.reserved?.[0] ?? 0, 0)
        var reserved2 = Math.max(referenceMonitor.reserved?.[2] ?? 0, 0)
        return Math.max((width - reserved0 - reserved2) / scale, 100)
    }
    
    property real referenceHeight: {
        if (!referenceMonitor) return 1080
        var height = Math.max(referenceMonitor.height ?? 1080, 480)
        var scale = Math.max(referenceMonitor.scale ?? 1, 0.1)
        var reserved1 = Math.max(referenceMonitor.reserved?.[1] ?? 0, 0)
        var reserved3 = Math.max(referenceMonitor.reserved?.[3] ?? 0, 0)
        return Math.max((height - reserved1 - reserved3) / scale, 60)
    }
    
    // All workspaces use the same size based on the reference monitor (smallest logical size)
    property real workspaceImplicitWidth: Math.max(100, referenceWidth * root.scale)
    property real workspaceImplicitHeight: Math.max(60, referenceHeight * root.scale)

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

    // Show on all monitors always
    visible: true
    opacity: 1.0

    // Shared wallpaper image - loaded once and reused
    Image {
        id: sharedWallpaper
        source: Appearance.background_image || ""
        visible: false // Hidden as it's only used as a source
        cache: true
        asynchronous: true
        smooth: true
        opacity: Appearance.workpaceTransparency
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
                            property int workspaceId: root.workspaceGroup * workspacesShown + rowIndex * ConfigOptions.overview.numOfCols + colIndex + 1
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
                            opacity: Appearance.workpaceTransparency

                            // Wallpaper background
                            Rectangle {
                                id: wallpaperContainer
                                anchors.fill: parent
                                anchors.margins: 2
                                radius: workspace.radius - 2
                                color: workspace.defaultWorkspaceColor
                                clip: true
                                
                                ShaderEffectSource {
                                    id: wallpaperSource
                                    anchors.fill: parent
                                    sourceItem: sharedWallpaper
                                    visible: sharedWallpaper.status === Image.Ready
                                    smooth: true
                                    
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
                                
                                Rectangle {
                                    anchors.fill: parent
                                    color: workspace.defaultWorkspaceColor
                                    visible: sharedWallpaper.status !== Image.Ready
                                }
                                
                                Rectangle {
                                    anchors.fill: parent
                                    color: hoveredWhileDragging ? hoveredWorkspaceColor : "black"
                                    opacity: hoveredWhileDragging ? 0.3 : 0.1
                                }
                            }

                            // Border overlay
                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                radius: parent.radius
                                border.width: 1
                                border.color: hoveredWhileDragging ? hoveredBorderColor : ColorUtils.transparentize(Appearance.m3colors.m3borderPrimary, 0.6)
                                z: 10
                            }

                            StyledText {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.topMargin: 12
                                anchors.leftMargin: 12
                                
                                text: workspaceId
                                font.pixelSize: root.workspaceNumberSize * root.scale
                                font.weight: Font.DemiBold
                                color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.8)
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignTop
                                z: 15
                            }

                            MouseArea {
                                id: workspaceArea
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                z: 20
                                onClicked: {
                                    if (root.draggingTargetWorkspace === -1) {
                                        GlobalStates.overviewOpen = false
                                        Hyprland.dispatch(`workspace ${workspaceId}`)
                                    }
                                }
                            }

                            DropArea {
                                anchors.fill: parent
                                z: 20
                                onEntered: {
                                    root.draggingTargetWorkspace = workspaceId
                                    if (root.draggingFromWorkspace == root.draggingTargetWorkspace) return;
                                    hoveredWhileDragging = true
                                }
                                onExited: {
                                    hoveredWhileDragging = false
                                    if (root.draggingTargetWorkspace == workspaceId) root.draggingTargetWorkspace = -1
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

            Repeater { // Window repeater - Show ALL windows with error handling
                model: ScriptModel {
                    values: windowAddresses.filter((address) => {
                        if (!address) return false
                        var win = windowByAddress[address]
                        if (!win || !win.workspace) return false
                        
                        var workspaceId = win.workspace.id
                        if (typeof workspaceId !== 'number' || workspaceId <= 0) return false
                        
                        // Show all windows in the current workspace group, regardless of monitor
                        return (root.workspaceGroup * root.workspacesShown < workspaceId && 
                                workspaceId <= (root.workspaceGroup + 1) * root.workspacesShown)
                    })
                }
                delegate: OverviewWindow {
                    id: window
                    windowData: windowByAddress[modelData]
                    // Always use this overview's monitor data for consistent workspace sizing
                    monitorData: root.monitorData
                    scale: root.scale
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
                            // Comprehensive error handling for window positioning
                            if (!windowData || !windowData.at || windowData.at.length < 2) {
                                console.warn("Invalid window data, skipping positioning")
                                return
                            }
                            
                            // Get the window's actual monitor data with fallbacks
                            var actualMonitorData = HyprlandData.monitors.find(m => m?.id === windowData?.monitor) || root.monitorData
                            if (!actualMonitorData) {
                                console.warn("Monitor data not found for window, using reference monitor")
                                actualMonitorData = root.referenceMonitor
                            }
                            
                            // Ensure valid monitor data
                            var monitorWidth = Math.max(actualMonitorData.width ?? 1920, 640)
                            var monitorHeight = Math.max(actualMonitorData.height ?? 1080, 480)
                            var monitorScale = Math.max(actualMonitorData.scale ?? 1, 0.1)
                            var monitorX = actualMonitorData.x ?? 0
                            var monitorY = actualMonitorData.y ?? 0
                            var reserved = actualMonitorData.reserved || [0, 0, 0, 0]
                            
                            // Ensure reserved values are valid
                            var reservedLeft = Math.max(reserved[0] ?? 0, 0)
                            var reservedTop = Math.max(reserved[1] ?? 0, 0)
                            var reservedRight = Math.max(reserved[2] ?? 0, 0)
                            var reservedBottom = Math.max(reserved[3] ?? 0, 0)
                            
                            // Calculate usable monitor dimensions (logical pixels)
                            var usableWidth = Math.max((monitorWidth - reservedLeft - reservedRight) / monitorScale, 100)
                            var usableHeight = Math.max((monitorHeight - reservedTop - reservedBottom) / monitorScale, 60)
                            
                            // Get raw window position (physical pixels)
                            var rawWindowX = windowData.at[0]
                            var rawWindowY = windowData.at[1]
                            
                            // Convert to monitor-relative position (subtract monitor offset)
                            var monitorRelativeX = rawWindowX - monitorX
                            var monitorRelativeY = rawWindowY - monitorY
                            
                            // Convert to logical pixels and adjust for reserved areas
                            var logicalX = Math.max((monitorRelativeX - reservedLeft) / monitorScale, 0)
                            var logicalY = Math.max((monitorRelativeY - reservedTop) / monitorScale, 0)
                            
                            // Calculate relative position (0.0 to 1.0) within the usable area
                            var relativeX = usableWidth > 0 ? Math.min(Math.max(logicalX / usableWidth, 0), 1) : 0
                            var relativeY = usableHeight > 0 ? Math.min(Math.max(logicalY / usableHeight, 0), 1) : 0
                            
                            // Map to workspace coordinates
                            var padding = Math.max(ConfigOptions.overview.windowPadding ?? 4, 0)
                            var workspaceWidth = Math.max(root.workspaceImplicitWidth - (padding * 2), 50)
                            var workspaceHeight = Math.max(root.workspaceImplicitHeight - (padding * 2), 30)
                            
                            // Calculate final position within the workspace
                            var workspaceX = relativeX * workspaceWidth
                            var workspaceY = relativeY * workspaceHeight
                            
                            // Add workspace offset and padding
                            window.x = workspaceX + xOffset + padding
                            window.y = workspaceY + yOffset + padding
                            
                            // Debug logging
                            console.log("Window positioning debug:")
                            console.log("  Raw position:", rawWindowX, rawWindowY)
                            console.log("  Monitor:", actualMonitorData.name, "Scale:", monitorScale)
                            console.log("  Monitor offset:", monitorX, monitorY)
                            console.log("  Reserved areas:", reserved)
                            console.log("  Logical position:", logicalX, logicalY)
                            console.log("  Usable dimensions:", usableWidth, usableHeight)
                            console.log("  Relative position:", relativeX, relativeY)
                            console.log("  Workspace offset:", xOffset, yOffset)
                            console.log("  Final position:", window.x, window.y)
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
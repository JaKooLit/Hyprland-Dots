import QtQuick
import Quickshell
import "root:/modules/common/functions/color_utils.js" as ColorUtils
pragma Singleton
pragma ComponentBehavior: Bound


Singleton {
    id: root
    property QtObject m3colors
    property QtObject animation
    property QtObject animationCurves
    property QtObject colors
    property QtObject rounding
    property QtObject font
    property QtObject sizes

    property real transparency: 0.5
    property real contentTransparency: 0.1
    property real workpaceTransparency: 0.8
    property string background_image: Directories.config + "/rofi/.current_wallpaper"
    
    m3colors: QtObject {
        property bool darkmode: true
        property bool transparent: true

        property color m3windowBackground: "#161217"
        property color m3primaryText: "#EAE0E7"
        property color m3layerBackground1: "#1F1A1F"
        property color m3layerBackground2: "#231E23"
        property color m3layerBackground3: "#2D282E"
        property color m3surfaceText: "#EAE0E7"
        property color m3secondaryText: "#CFC3CD"
        property color m3borderPrimary: "#cba6f7"
        property color m3shadowColor: "#000000"
        property color m3accentPrimary: "#E5B6F2"
        property color m3accentSecondary: "#D5C0D7"
        property color m3selectionBackground: "#534457"
        property color m3accentPrimaryText: "#452152"
        property color m3selectionText: "#F2DCF3"
        property color m3borderSecondary: "#4C444D"

        property color colTooltip: "#1e1e2e"
        property color colOnTooltip: "#F8F9FA"
    }

    colors: QtObject {
        property color colSubtext: m3colors.m3borderPrimary
        property color colLayer0: ColorUtils.transparentize(m3colors.m3windowBackground, root.transparency)
        property color colLayer1: ColorUtils.transparentize(ColorUtils.mix(m3colors.m3layerBackground1, m3colors.m3windowBackground, 0.7), root.contentTransparency);
        property color colOnLayer1: m3colors.m3secondaryText;
        property color colLayer2: ColorUtils.transparentize(ColorUtils.mix(m3colors.m3layerBackground2, m3colors.m3layerBackground3, 0.55), root.contentTransparency)
        property color colOnLayer2: m3colors.m3surfaceText;
        property color colLayer1Hover: ColorUtils.transparentize(ColorUtils.mix(colLayer1, colOnLayer1, 0.92), root.contentTransparency)
        property color colLayer1Active: ColorUtils.transparentize(ColorUtils.mix(colLayer1, colOnLayer1, 0.85), root.contentTransparency);
        property color colLayer2Hover: ColorUtils.transparentize(ColorUtils.mix(colLayer2, colOnLayer2, 0.90), root.contentTransparency)
        property color colLayer2Active: ColorUtils.transparentize(ColorUtils.mix(colLayer2, colOnLayer2, 0.80), root.contentTransparency);
        property color colPrimary: m3colors.m3accentPrimary
        property color colPrimaryHover: ColorUtils.mix(colors.colPrimary, colLayer1Hover, 0.87)
        property color colPrimaryActive: ColorUtils.mix(colors.colPrimary, colLayer1Active, 0.7)
        property color colShadow: ColorUtils.transparentize(m3colors.m3shadowColor, 0.7)
    }

    rounding: QtObject {
        property int unsharpen: 2
        property int verysmall: 8
        property int small: 12
        property int normal: 17
        property int large: 23
        property int verylarge: 30
        property int veryverylarge: 60
        property int full: 9999
        property int screenRounding: veryverylarge
        property int windowRounding: veryverylarge
    }

    font: QtObject {
        property QtObject family: QtObject {
            property string uiFont: "Open Sans"
            property string iconFont: "FiraConde Nerd Font"
            property string codeFont: "JetBrains Mono NF"
        }
        property QtObject pixelSize: QtObject {
            property int textSmall: 13
            property int textBase: 15
            property int textMedium: 16
            property int textLarge: 19
            property int iconLarge: 22
        }
    }

    animationCurves: QtObject {
        readonly property list<real> expressiveFastSpatial: [0.42, 1.67, 0.21, 0.90, 1, 1] // Default, 350ms
        readonly property list<real> expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1.00, 1, 1] // Default, 500ms
        readonly property list<real> expressiveSlowSpatial: [0.39, 1.29, 0.35, 0.98, 1, 1] // Default, 650ms
        readonly property list<real> expressiveEffects: [0.34, 0.80, 0.34, 1.00, 1, 1] // Default, 200ms
        readonly property list<real> emphasized: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
        readonly property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
        readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        readonly property list<real> standardAccel: [0.3, 0, 1, 1, 1, 1]
        readonly property list<real> standardDecel: [0, 0, 0, 1, 1, 1]
    }

    animation: QtObject {
        property QtObject elementMove: QtObject {
            property int duration: 500
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.expressiveDefaultSpatial
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMove.duration
                    easing.type: root.animation.elementMove.type
                    easing.bezierCurve: root.animation.elementMove.bezierCurve
                }
            }
            property Component colorAnimation: Component {
                ColorAnimation {
                    duration: root.animation.elementMove.duration
                    easing.type: root.animation.elementMove.type
                    easing.bezierCurve: root.animation.elementMove.bezierCurve
                }
            }
        }
        property QtObject elementMoveEnter: QtObject {
            property int duration: 400
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.emphasizedDecel
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMoveEnter.duration
                    easing.type: root.animation.elementMoveEnter.type
                    easing.bezierCurve: root.animation.elementMoveEnter.bezierCurve
                }
            }
        }
        property QtObject elementMoveExit: QtObject {
            property int duration: 200
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.emphasizedAccel
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMoveExit.duration
                    easing.type: root.animation.elementMoveExit.type
                    easing.bezierCurve: root.animation.elementMoveExit.bezierCurve
                }
            }
        }
        property QtObject elementMoveFast: QtObject {
            property int duration: 200
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.expressiveEffects
            property int velocity: 850
            property Component colorAnimation: Component { ColorAnimation {
                duration: root.animation.elementMoveFast.duration
                easing.type: root.animation.elementMoveFast.type
                easing.bezierCurve: root.animation.elementMoveFast.bezierCurve
            }}
            property Component numberAnimation: Component { NumberAnimation {
                    duration: root.animation.elementMoveFast.duration
                    easing.type: root.animation.elementMoveFast.type
                    easing.bezierCurve: root.animation.elementMoveFast.bezierCurve
            }}
        }

        property QtObject clickBounce: QtObject {
            property int duration: 200
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.expressiveFastSpatial
            property int velocity: 850
            property Component numberAnimation: Component { NumberAnimation {
                    duration: root.animation.clickBounce.duration
                    easing.type: root.animation.clickBounce.type
                    easing.bezierCurve: root.animation.clickBounce.bezierCurve
            }}
        }
        property QtObject scroll: QtObject {
            property int duration: 400
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.standardDecel
        }
        property QtObject menuDecel: QtObject {
            property int duration: 350
            property int type: Easing.OutExpo
        }
    }

    sizes: QtObject {
        property real barHeight: 40
        property real notificationPopupWidth: 410
        property real searchWidthCollapsed: 260
        property real searchWidth: 450
        property real hyprlandGapsOut: 5
        property real elevationMargin: 10
        property real fabShadowRadius: 5
        property real fabHoveredShadowRadius: 7
    }
}

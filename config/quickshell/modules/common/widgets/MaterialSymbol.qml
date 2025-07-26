import "root:/modules/common/"
import QtQuick

Text {
    id: root
    property real iconSize: Appearance?.font.pixelSize.textBase ?? 16
    property real fill: 0
    renderType: Text.NativeRendering
    font.hintingPreference: Font.PreferFullHinting
    verticalAlignment: Text.AlignVCenter
    font.family: Appearance?.font.family.iconFont ?? "Material Symbols Rounded"
    font.pixelSize: iconSize
    color: Appearance.m3colors.m3primaryText

    Behavior on fill {
        NumberAnimation {
            duration: Appearance?.animation.elementMoveFast.duration ?? 200
            easing.type: Appearance?.animation.elementMoveFast.type ?? Easing.BezierSpline
            easing.bezierCurve: Appearance?.animation.elementMoveFast.bezierCurve ?? [0.34, 0.80, 0.34, 1.00, 1, 1]
        }
    }

    font.variableAxes: { 
        "FILL": fill,
        "opsz": iconSize,
    }
}

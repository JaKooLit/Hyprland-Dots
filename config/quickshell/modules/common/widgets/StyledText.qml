import "root:/modules/common"
import QtQuick

Text {
    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
    font {
        hintingPreference: Font.PreferFullHinting
        family: Appearance?.font.family.uiFont ?? "sans-serif"
        pixelSize: Appearance?.font.pixelSize.textBase ?? 15
    }
    color: Appearance?.m3colors.m3primaryText ?? "black"
}

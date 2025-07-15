import "root:/modules/common"
import QtQuick
import QtQuick.Controls

TextArea {
    renderType: Text.NativeRendering
    selectedTextColor: Appearance.m3colors.m3selectionText
    selectionColor: Appearance.m3colors.m3selectionBackground
    placeholderTextColor: Appearance.m3colors.m3borderPrimary
    font {
        family: Appearance?.font.family.uiFont ?? "sans-serif"
        pixelSize: Appearance?.font.pixelSize.textBase ?? 15
        hintingPreference: Font.PreferFullHinting
    }
}

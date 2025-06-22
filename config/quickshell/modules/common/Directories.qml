pragma Singleton
pragma ComponentBehavior: Bound

import "root:/modules/common/functions/file_utils.js" as FileUtils
import Qt.labs.platform
import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    // XDG Dirs, with "file://"
    readonly property string config: StandardPaths.standardLocations(StandardPaths.ConfigLocation)[0]
    readonly property string state: StandardPaths.standardLocations(StandardPaths.StateLocation)[0]
    readonly property string gen_cache: StandardPaths.standardLocations(StandardPaths.GenericCacheLocation)[0]
    
    // Other dirs used by the shell, without "file://"
    property string shellConfig: FileUtils.trimFileProtocol(`${Directories.config}/quickshell`)
    property string shellConfigPath: `${Directories.shellConfig}/config.json`
    property string generatedMaterialThemePath: `${Directories.shellConfig}/qml_color.json`
}

const { Gtk } = imports.gi;
import Variable from 'resource:///com/github/Aylur/ags/variable.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { exec, execAsync } = Utils;

Gtk.IconTheme.get_default().append_search_path(`${App.configDir}/assets/icons`);

// Screen size
export const SCREEN_WIDTH = Number(exec(`bash -c "hyprctl monitors -j | jq '.[0].width / .[0].scale'"`));
export const SCREEN_HEIGHT = Number(exec(`bash -c "hyprctl monitors -j | jq '.[0].height / .[0].scale'"`));

// Mode switching
export const currentShellMode = Variable('normal', {}) // normal, focus
globalThis['currentMode'] = currentShellMode;
globalThis['cycleMode'] = () => {
    if (currentShellMode.value === 'normal') {
        currentShellMode.value = 'focus';
    } else {
        currentShellMode.value = 'normal';
    }
}

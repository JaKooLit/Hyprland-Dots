# CHANGES: Hyprland-Dots v2.3.18

## FIXES:

- Fixed: Overview Toggle keyind SUPER + A now properly detects QuickShell
  - If QS fails, or not installed AGS will be started instead
- Fixed: Super J/K cycle next/prev weren't working in both master / dwindle
- Fixed: Weather.py one-off run
- Removed: Hyprsunt from status group.
  - Credit: Alberson Miranda
- Added: more application icons for waybars
- Weather.py basically rewritten to improve look and functionality
  - Credit: Prabin Panta
  - The Jak team also heavily contributed to the rewrite
- Fixed: Waybar
  - Changing the waybar config `SUPERALT + B` would sometimes need to be done twice
  - Cause: options were incorrect annotated with "👉 ${name}"
- Fixed: `GameMode.sh` to function consistently
- Updated: `WalllustSwww.sh` wallpaper path
- Corrected: Typo in Show Open Apps
- GameMode.sh / Refresh.sh  
  - Enabling / Disabling repeatedly would result in multiple waybars 
  - Added additional `sleep` commands in `GameMode.sh` and `Refresh.sh`
  - Resolves [Issue 870](https://github.com/JaKooLit/Hyprland-Dots/issues/870)

## CHANGES:

- Changed: Hyprland Packages from SID
  - No longer built from source
  - Hyprland Version @ v0.51.1
  - If/When SID it updated, updates will be done as normal process
- Lock screen:
  - Clock now horizontal and smaller
  - Adjust spacing margines of the various fields
  - Small changes to color variabbles Trying to balance colors
  - Fixed both 1080 and 2K+ configurations
- `UserConfigs/Startup_App.conf` is now sourced in `hyprland.conf`
  - It was being sourced twice
- Some scripts weren't executable
  - `scripts/Battery.sh`
  - `scripts/ComposeHyprConfigs.sh`
  - `scripts/OverviewToggle.sh`
  - `scripts/sddm_wallpaper.sh`
- Updated: SWWW to v0.11.2
  - Fixes numerous issues
  - Portrait monitors especially
  - SWWW isn't being maintained In future will switch to AWWWW
- Added: A message before installing wallpapers that some are AI generated or enhanced
- Changed: `/usr/bin/bash` to `/usr/bin/evn bash` for better portability
- Adjusted: Small change to `DropDownterminal.sh`
  - Increased top margin % to center it more
  - Widened it.
  - These options are settable in the script.

## FEATURES:

- Hyprsunet retains last state on/off
  - Credit: Alberson Miranda
- Fastfetch now displays the version of the Jak Dotfiles
- ChangeLayout.sh
  - Dynamically binds SUPER J/K based on current layout
  - Previously only worked in Master Layout
  - Credit: Suresh Thagunna
  - Along with that KeybindsLayoutInit script reads current default layout
  - Then it adjusts the SUPER J/K keybindings appropriately
- RofiBeats dynamic music system added
- Binds now include descriptions.
  - Switched from `bind` to `bindd`
  - Improves usability of keybind search
- Add new laptop gesture for zoom system. 

Thanks to everyone that contributed, or reported issues.

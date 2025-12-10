# Changelog — JAK's Hyprland Dotfiles

## v2.3.18 — 2025-12-10

## FIXES:

- Fixed: Opacity for `vscode` configured multiple times
- Fixed: Quickshell `overview` not working, error "Quickshell or AGS not installed"
  - If `shell.qml` exists in `~/.config/quickshell` that blocks overview
  - That file isn't configured for overview
  - Without that file, it will look in the `overview` directory and load the QML code
- Fixed: Waybar Modules, locale not included in clock format
  - Always showed US-EN
  - Thanks to albersonmiranda for finding and fixing it
- Fixed: Not all waybars had `custom/nightlight`
- Fixed: `Weather.py` cache wasn't updating when UNITS changed from C to F
- Fixed: Wallpapers with periods in names truncated
  - https://github.com/JaKooLit/Hyprland-Dots/pull/873
  - Thanks to @godlyfast for the fix.
- Fixed: Overview Toggle keyind SUPER + A now properly detects QuickShell
  - If QS `overview` fails, or is not installed, AGS `overview` will be started instead
- Fixed: `Super J/K` cycle next/prev weren't working in both master / dwindle
- Fixed: `Weather.py` one-off run
- Removed: `Hyprsunset` from status group.
  - Credit: Alberson Miranda
- Added: more application icons for waybars
- `Weather.py` basically rewritten to improve look and functionality
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

- ChangeLayout.sh continues to rebind dynamically when layouts are toggled.
  - Credits: [Suresh Thagunna](https://github.com/suresh466)
  - For identifying the mismatch and proposing an auto-alignment approach.

- Startup config order:
  - load System Defaults Startup_Apps and WindowRules first
  - Then user overlays, restoring baseline autostarts while keeping user additions.
- Lock screen:
  - Clock now horizontal and smaller
  - Adjust spacing margines of the various fields
  - Small changes to color variables Trying to balance colors
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

- Hyprsunset retains last state on/off
  - Credit: Alberson Miranda
- Fastfetch now displays the version of the Jak Dotfiles
- `ChangeLayout.sh`
  - Dynamically binds SUPER J/K based on current layout
  - Previously only worked in Master Layout
  - Credit: Suresh Thagunna
  - Along with that `KeybindsLayoutInit` script reads current default layout
  - Then it adjusts the SUPER J/K keybindings appropriately
- RofiBeats dynamic music system added
- Binds now include descriptions.
  - Switched from `bind` to `bindd`
  - Improves usability of keybind search
- Add new laptop gesture for zoom system.

Thanks to everyone that contributed, or reported issues.

Contributors:

Alberson Miranda
TheAhumMaitra
Prabin Panta
Suresh Thagunna
@goldlyfast

## October 2025

### ⌨️ Keybinds

- Convert Hyprland keybinds to description form (`bindd`, `bindld`, `binded`,
  `bindmd`, `bindlnd`) in `config/hypr/...`.
- Add concise descriptions for each keybind; keep the name "powermenu".
- Update `config/hypr/scripts/KeyBinds.sh` to parse and display descriptions as:
  MODS+KEY — DESCRIPTION — DISPATCHER [PARAMS].

### 🐛 Fixes

- Updated `/bin/bash` to `/usr/bin/env bash`
- Correct `windowrule` syntax error.
- Ensure wallpaper selector applies wallpaper to SDDM.
- Update theme colors when a new wallpaper is selected.

### 🖥️ Jak dotfiles version now in `fastfetch` output.

### 🌦️ Weather.py

Key Changes:

- 2nd Weather.py Update by prabinpanta0
- ♻️ Substantial rewrite.
- ✨ New unified weather entrypoint (weatherWrap.sh)
  - With Python-first execution
- 🔒 Automatic weather updates before screen lock
- 🚀 Weather cache initialization at session startup
- 🛡️ Enhanced error handling and fallback mechanisms
- 📍 Automatic location detection via IP geolocation
- 🎨 Improved weather condition mapping and JSON output

### 🖥️ Support for debian and ubuntu installs

- Providing they are using Hyprland 0.51.1 or greater

### 🖥️ Drop-down terminal

- 🔧 Start on login via `TerminalDropDown.sh` so first invocation works.
- 🐱 Use Kitty explicitly instead of `$TERM` for consistent behavior.

### 🌇 HyprSunset

- 🔧 Availble from waybar or`SUPER + N`

### 🖱️ Gestures

- 🔧 Updated to accommodate Hyprland 0.5x changes.

### 👥 Contributors

- [prabinpanta0](https://github.com/prabinpanta0)
- [CharlyMH](https://github.com/CharlyMH)
- [ndeekshith](https://github.com/ndeekshith)
- [SherLock707](https://github.com/SherLock707)
- [SVIGHNESH](https://github.com/SVIGHNESH)

If you have any questions, feel free to contact via
[GitHub Discussions](https://github.com/JaKooLit/Hyprland-Dots/discussions) or
[Through Discord Server](https://discord.gg/kool-tech-world)

# Changelog — JAK's Hyprland Dotfiles

## v2.3.20

- Bugfix release
- Fixed issue with express-update
  - It bypassed the code to remove duplicates in system vs. user
  - Now checks for dups in version <= 2.3.19
  - Improved the checking code for better matching system vs. User
  - Merged `tak0dan` update to `Tak0-Autodispatch.sh` script
  - Removed stale `nvim` config. It was never copied but not needed

## v2.3.19

- 2026-01-20
- Fixed CSS to format the `custom/nightlight` module
- Fixed padding on some CSS files

- 2026-01-19
- Removed "Set wallpaper SDDM prompt"
- When changing wallpaper there is no longer a prompt to set it on SDDM
- It's now a menu option under Quick Settings menu `SUPER SHIFT + E`
- Fixed `Glass` style sheets

- 2026-01-16
- Added `Rainbow Borders sub memu`
  - Code provided by [brunoorsolon](https://github.com/brunoorsolon)
  - There are now mulitple modes for the Rainbow Borders feature
  - `Disabled`, `Wallust Color`, `Rainbow`, `Gradient flow`
  - Thank you for the submission
- Disabled `RainbowBorders.sh` by default
- Use the quick setings menu `SUPERSHIFT + E` to enable, select mode

- 2026-01-15
- Created waybar configs for ML4W Glass style
- `TOP & Bottom Summit - glass`
- `Default Laptop - Glass`
- `Everforest - Glass`
- Fixed menu for express-update
- Fixed `Toggle Rainbow` checked for wrong file

- 2026-01-13
- Added `Toggle Rainbow borders` option to settings menu
- `SUPERSHIFT+E` search for `Rainbow`
- It will toggle the current state and run `Refresh.sh` to start or stop
  - Thanks to @Arkboi for suggesting it.
  - Later if there are more settings like this I will create a new menu

- 2026-01-11
  - Improved `ML4W Glass` theme
    - Now has proper 3d gradient look
    - Theme based nightlight color
  - `copy.sh` is now more modular
    - Helper scripts in `scripts` dir per function
    - Making `copy.sh` smaller (1200 lines to 800 so far)
    - Easier to maintain going forward

- 2026-01-09
  - Fixed: Keybind parser latency
    - Changed the parsing login to python instead of bash
    - Also fixed duplicates when you unmap, then remap keybinds
      - Ex. Change keybind for `file manger`
        - Both the old and new keybind were show in keybind menu
  - Added: `--express-update` to `copy.sh`
    - `./copy.sh --express-update`
    - This will bypass some of the questions
      - Updating SDDM wallpaper
      - Downloading wallpaper from repo
        - Mostly like that was done at install time or previous upgrade
      - Restoring User configs :
        - `Weather.sh` and `Weather.sh`
        - `Rofibeats.sh`
        - etc.
      - Automatically trims the backed up directories leaving just latest backup
      - This dramatically reduces the time/effort to update dotfiles
        - Most users don't restore these custom files on upgrades

- 2026-01-08
- Fixed: MPRIS artwork in Sway notification center only 10 pixels
  - Adjusted to 96 pixels
  - Thank you @godlyfas for fixing this
- Fixing scripts
  - `TouchPad.sh` never expands `$TOUCHPAD_ENABLED` (and doesn’t source the file that defines it)
  - `Volume.sh` has multiple microphone-control bugs (bad `pamixer` arguments, typoed function name, invalid notification payloads) that break mic toggling and volume feedback.
  - `DarkLight.sh` wipes the Qt theme paths each run because the `qt5ct/qt6ct` palette variables are commented out.
  - `KooLsDotsUpdate.sh` contains a malformed `notify-send` string that crashes the script when no local version is detected.
  - `Distro_update.sh` runs `sudo apt upgrade` outside the kitty window, so the Debian/Ubuntu flow never finishes inside the terminal.
  - `Hypridle.sh` now launches `hypridle` in the background (`& disown`) when enabling the daemon, preventing the toggle command from hanging Waybar.
  - `RofiSearch.sh` verifies that `jq` is available, captures the user’s query explicitly, URL-encodes it via `jq` `@uri`,
    - opens the configured search engine with the encoded query instead of dropping the term.
  - `Sounds.sh` now tries `pw-play`, then `paplay`, then `aplay`, emitting a clear error if none are installed, so the script no longer calls the non-existent pa-play.
  - `Tak0-Per-Window-Switch.sh` now records the listener PID in `~/.cache/kb_layout_per_window.listener.pid` and reuses it if still running, preventing multiple background listeners, and reports missing Hyprland sockets without exiting the main script.
  - `WaybarScripts.sh` adds a `launch_files()` helper that checks `$files` before execution; if unset, it shows a notification instead of running an empty command.
  - `sddm_wallpaper.sh` validates `~/.config/rofi/wallust/colors-rofi.rasi` before use, extracts colors via a helper, and aborts with a notification if any required colors are missing.
  - `WallustSwww.sh` now reads the focused monitor’s cache file (or parses swww query per-monitor) to pick the correct wallpaper path
    - Eliminating the previous “last line wins” bug on multi-monitor setups.
    - Wallpaper and global theme changes are now dramatically faster
  - `PortalHyprland.sh` suppresses harmless killall errors and launches only the first available portal binary in each category (hyprland + general)
    - Avoiding duplicate processes when both `/usr/lib` and `/usr/libexec` variants exist.
  - `KillActiveProcess.sh` checks that Hyprland returned a numeric PID before calling kill
    - Notifies the user when no active window is available instead of throwing kill usage errors.

- 2026-01-06
  - Added Global Theme Changer.
    - There are many themes to choose from
    - `SUPER + T`
  - Added "Glass Style" taken from `ML4W` dotfiles
    - Thank you [TheAhumMaitra](https://github.com/TheAhumMaitra)
  - Fixed more WindowRules
  - Fixed rofi themes to work with Theme changer
  - Added `ghostty` terminal config file integrated with Themes
    - `ghostty` is not installed by default
    - The `COPR` is already there for Fedora
      - `sudo dnf install ghostty`
  - The `COPR` repo for `wezterm` is also available
    - `sudo dnf install wezterm`
    - A config file is already available when you install it
    - Most other distros have these terminals in their repo

- 2026-01-04
- Fullscreen or maximized would exit using `ALT-TAB` (cycle next/bring-to-front)
  - User `GoodBorn` found this fix

  ```
  misc {
   on_focus_under_fullscreen = 1
   # 0 - Default, no change
   # 1 - New focused window takes over fullscreen (Windows-like Alt-Tab)
   # 2 - New focused window stays behind the fullscreen one
   }
  ```

  > Note: The above change only works on Hyprland v0.53+.
  > Users with lower will have to comment that line out.
  > `~/.config/hypr/UserSettings/SystemSettings.conf`

- Added: modal rule so popup diaglog, like `Save as` or `Open File` center and float by default
  - `windowrule = float on, center on, match:modal:1`

- 2026-01-01
- Added more blur and enabled xray
  - Thank you [TheAhumMaitra](https://github.com/TheAhumMaitra)

- 2025-12-31
  - Fixed rule for `Gnome Calculator`
    - Thanks Warlord for finding/fixing that
  - Fixed rule for `yad`
    - Size was being overridden by `settings` tag
  - `~/Pictures` now follows `XDG dir` vs. hard coded
    - Thanks for Jaël Champagne Gareau for the code
  - Fixed `opache toggle`
  - `Weather.py` and `Weather.sh` updated and improved
    - Thank you Lumethra
  - Added network check to `WeatherWrap` script
    - Thank you Maximilian Zhu
  - Added sample workspace rules to start apps on specific workspaces
    - They are commented out but serve as references

- 2025-12-29
  - Fixed pathing in Wallust script
    - Thank you [Lumethra](https://github.com/Lumethra)

— 2025-12-22

- Added:
  - Optional keybinding to increment/decrement audio in 1% steps vs. 5%
    - Thanks [rgarofono](https://github.com/rgarofano) for the code
- Fixed:
  - Switch Layout was looking in wrong location
  - SUPER - J/K not working in both `master` and `dwindle` layouts
    - You also get notification message on layout change
    - Thanks [@suresh466](https://github.com/suresh466) for fixing it

## v2.3.18 — 2025-12-10

## FIXES:

- Updated: Made the WindowRules file for 0.53+ the default
  - There are more distros now running 0.53.1 vs. earlier versions
  - The older file is still there for those users not yet up to date
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

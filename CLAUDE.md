# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository contains JaKooLit's Hyprland dotfiles - a comprehensive configuration collection for the Hyprland Wayland compositor. It provides pre-configured setups for multiple Linux distributions and includes scripts for installation, backup, and updates.

**Key Point**: This is a dotfiles repository, not an application. The code here configures desktop environments, not builds software packages.

## Installation & Update Commands

### Initial Installation
```bash
# Clone and install dotfiles
git clone --depth=1 https://github.com/VictorVilelaSilva/Hyprland-Dots-Victor
cd Hyprland-Dots
chmod +x copy.sh
./copy.sh
```

### Updating Existing Installation
```bash
# Semi-automatic update (preserves UserConfigs and UserScripts)
chmod +x upgrade.sh
./upgrade.sh
```

### Release Version Installation
```bash
# Install from stable release
chmod +x release.sh
./release.sh
```

**Important**: Do NOT run these scripts as root - they will exit with an error.

## Architecture

### Configuration Hierarchy

The Hyprland configuration uses a layered architecture that separates vendor defaults from user customizations:

**Main Entry**: `config/hypr/hyprland.conf`
- Sources all configuration files in a specific order
- Uses two primary directories:
  - `$configs` = `~/.config/hypr/configs/` (vendor defaults)
  - `$UserConfigs` = `~/.config/hypr/UserConfigs/` (user overrides)

**Overlay System**: User files override vendor defaults without modifying the originals. For example:
- `configs/Startup_Apps.conf` contains default startup applications
- `UserConfigs/Startup_Apps.conf` contains user additions
- Both are sourced, with user additions taking precedence

**Critical Files in UserConfigs/**:
- `01-UserDefaults.conf` - Default applications (browser, terminal, editor)
- `ENVariables.conf` - Environment variables (NVIDIA, cursor, editor)
- `UserSettings.conf` - Main Hyprland settings
- `UserKeybinds.conf` - Custom keybindings
- `UserDecorations.conf` - Window decorations
- `UserAnimations.conf` - Animation settings
- `WindowRules.conf` - Window and layer rules
- `Laptops.conf` / `LaptopDisplay.conf` - Laptop-specific settings

### Scripts Organization

**config/hypr/scripts/**: Main utility scripts
- `Refresh.sh` - Refresh Waybar and other components
- `WallustSwww.sh` - Wallpaper management with wallust theming
- `ScreenShot.sh` - Screenshot utilities
- `LockScreen.sh` - Hyprlock management
- `KeyHints.sh` - Display keybind hints
- `WaybarLayout.sh` / `WaybarStyles.sh` - Waybar theme management
- `Distro_update.sh` - KooL's Dots update script
- And many more utility scripts for brightness, volume, media control, etc.

**config/hypr/UserScripts/**: User-customizable scripts
- `Weather.sh` / `Weather.py` - Weather information
- `RofiBeats.sh` - Lofi/beats player
- `WallpaperAutoChange.sh` - Automatic wallpaper rotation
- `RainbowBorders.sh` - Animated rainbow borders

### Component Configuration Directories

- **waybar/**: Status bar configuration
  - `configs/` - Layout presets (Default, Laptop variants)
  - `style/` - CSS themes
  - `Modules` - Module definitions
  - Symlinks `config` and `style.css` point to active layout/theme

- **rofi/**: Application launcher and menus
  - Theming controlled by wallust color scheme
  - Global font configuration in `0-shared-fonts.rasi`

- **hypr/wallust/**: Color scheme generation
  - Generates themes based on wallpaper colors
  - Affects Waybar, Rofi, Kitty, and more

- **Other key configs**: ags/, quickshell/, kitty/, swaync/, wlogout/, fastfetch/

### Version Management

Version tracking file: `config/hypr/v*.*.*` (e.g., `v2.3.18`)
- Used by upgrade.sh to detect version differences
- Determines whether to use bulk or selective restore mode

### Hardware Detection & Auto-Configuration

The `copy.sh` script automatically detects and configures for:
- **NVIDIA GPUs**: Enables proper environment variables and cursor settings
- **Virtual Machines**: Sets software rendering and cursor options
- **NixOS**: Configures NixOS-specific polkit
- **Laptop vs Desktop**: Adjusts Waybar layout and settings
- **ASUS laptops**: Adds rog-control-center to startup
- **Hyprcursor support**: Activates if Bibata-Modern-Ice/hyprcursors exists

## Development Guidelines

### Modifying Configurations

1. **Never edit files in configs/** - These are vendor defaults and will be overwritten during updates
2. **Always edit files in UserConfigs/** - These persist across updates
3. **UserScripts/** directory is never touched by upgrade.sh - safe for custom scripts

### Script Execution Context

- All scripts assume `~/.config/hypr/` as the base directory
- Scripts use `$scriptsDir` variable defined in Hyprland configs
- Most scripts require specific utilities: rofi, waybar, swww, wallust, etc.

### Backup Behavior

All installation/update scripts create timestamped backups:
- Format: `directory-backup-MMDD_HHMM`
- Example: `~/.config/hypr-backup-0112_1430`
- copy.sh creates backups in `~/.config/`
- upgrade.sh creates backups with `-b4-upgrade` suffix

### Window Rules and Startup Apps

Starting from v2.3.19, these use an overlay + disable system:
- `UserConfigs/Startup_Apps.conf` - Additional exec-once lines
- `UserConfigs/Startup_Apps.disable` - List of default apps to disable
- `UserConfigs/WindowRules.conf` - Additional window/layer rules
- `UserConfigs/WindowRules.disable` - List of default rules to disable

### Shell Script Standards

- Always use `#!/usr/bin/env bash` shebang
- Include copyright header: `# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */ #`
- Use color codes defined at script start (OK, ERROR, NOTE, INFO, WARN, CAT)
- Log important operations to dated log files
- Check for required commands with `command -v`

## Common Workflows

### Testing Configuration Changes

```bash
# Reload Hyprland configuration
# Use SUPER + R keybind (default) or:
hyprctl reload

# Restart Waybar
pkill waybar && waybar &

# Refresh all components
~/.config/hypr/scripts/Refresh.sh
```

### Changing Wallpapers

```bash
# Manual wallpaper selection (SUPER + W)
~/.config/hypr/UserScripts/WallpaperSelect.sh

# This automatically:
# 1. Sets wallpaper with swww
# 2. Generates color scheme with wallust
# 3. Updates Waybar, Kitty, Rofi themes
```

### Adding Custom Startup Applications

Add to `~/.config/hypr/UserConfigs/Startup_Apps.conf`:
```
exec-once = your-application
```

### Keyboard Layout Configuration

Keyboard layout is critical - incorrect layout causes Hyprland crashes.
- Set in: `config/hypr/configs/SystemSettings.conf` (kb_layout)
- Or user override: `UserConfigs/UserSettings.conf`
- copy.sh detects and prompts for layout verification

## Important Notes

### Display Resolution Settings

- Dots are optimized for 1440p (2K) displays
- For <1440p: copy.sh adjusts font sizes in kitty, rofi, hyprlock
- For laptops: Different Waybar configs and hypridle settings

### NVIDIA Configuration

If NVIDIA GPU detected, copy.sh uncomments:
- `env = LIBVA_DRIVER_NAME,nvidia`
- `env = __GLX_VENDOR_LIBRARY_NAME,nvidia`
- `env = NVD_BACKEND,direct`
- Sets `no_hardware_cursors = 1`

Edit `~/.config/hypr/UserConfigs/ENVariables.conf` for custom adjustments.

### Alternative Bars: AGS and Quickshell

If `ags` or `qs` (quickshell) is installed, copy.sh automatically:
- Adds them to Startup_Apps.conf
- Enables them in Refresh.sh and RefreshNoWaybar.sh
- For Quickshell: Uses `qs -c overview` configuration

### Time Format

Default: 24-hour format
To change to 12-hour: copy.sh modifies:
- Waybar clock modules in `config/waybar/Modules`
- Hyprlock time display in `config/hypr/hyprlock.conf`
- SDDM themes if installed

## Troubleshooting

### Common Issues

1. **Hyprland won't start**: Check keyboard layout in SystemSettings.conf
2. **Waybar not loading**: Verify symlinks exist: `~/.config/waybar/config` and `~/.config/waybar/style.css`
3. **Scripts not executable**: Run `chmod +x ~/.config/hypr/scripts/* ~/.config/hypr/UserScripts/*`
4. **Themes not applying**: Run wallust: `wallust run -s ~/.config/hypr/wallpaper_effects/.wallpaper_current`

### Log Files

- Installation logs: `Copy-Logs/install-DD-HHMMSS_dotfiles.log`
- Upgrade logs: `Upgrade-Logs/upgrade-DD-HHMMSS_upgrade_dotfiles.log`

## Distribution Support

This dotfiles repository supports installation via distribution-specific scripts:
- Arch Linux
- Fedora (43/Rawhide)
- OpenSUSE Tumbleweed
- Debian (Trixie & SID)
- Ubuntu (24.04 LTS, 25.10)
- NixOS (25.05+)

Debian/Ubuntu require Hyprland v0.50+. The distro install scripts handle package installation; this repo only contains configurations.

## External Resources

- [Wiki](https://github.com/JaKooLit/Hyprland-Dots/wiki)
- [Keybinds](https://github.com/JaKooLit/Hyprland-Dots/wiki/Keybinds)
- [Changelogs](https://github.com/JaKooLit/Hyprland-Dots/wiki/Changelogs)
- [Hyprland Official Wiki](https://wiki.hyprland.org/)

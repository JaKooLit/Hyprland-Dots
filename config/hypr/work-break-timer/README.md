# Work Break Timer for Hyprland + Waybar

A comprehensive work/break management system that helps you maintain healthy work habits with automated break reminders.

## Features

- **Automated Break Reminders**
  - Short breaks: Every 10 minutes (10 second break)
  - Long breaks: Every 1 hour (10 minute break)
  - Fullscreen terminal overlay with animated countdown
  - Customizable intervals and durations

- **Intelligent Idle Detection** 🆕
  - Automatically pauses timer when you're away from PC
  - Resets break countdown after 5 minutes of inactivity (configurable)
  - Only counts active work time towards breaks
  - Prevents unwanted break interruptions when returning
  - Tracks keyboard/mouse activity via system interrupts

- **Waybar Integration**
  - Real-time countdown display
  - Visual status indicators (working/paused/break)
  - Color-coded states with Catppuccin theme
  - Click actions for quick control

- **Break Controls**
  - Skip current break (ESC or 's' key)
  - Postpone break by 5 minutes ('p' key)
  - Pause/resume timer
  - Interactive menu for all actions

- **Configuration**
  - JSON-based config file
  - Rofi-based settings editor
  - Manual config editing support

## Files Created

```
~/.config/work-break-timer/
├── config.json                          # Main configuration file
├── state.json                           # Runtime state (auto-generated)
└── README.md                            # This file

~/.config/hypr/scripts/
├── WorkBreakTimer.py                    # Main daemon
├── WorkBreakTimerStatus.sh              # Waybar status script
├── WorkBreakTimerControl.sh             # Control script
└── BreakOverlay.sh                      # Fullscreen break overlay

~/.config/waybar/
├── config                               # Updated with timer module
└── ModulesCustom                        # Updated with timer definition

~/.config/waybar/style/
└── [Catppuccin] Mocha Transparent.css  # Updated with timer styling

~/.config/hypr/UserConfigs/
└── Startup_Apps.conf                    # Updated with autostart
```

## Configuration

Edit `~/.config/work-break-timer/config.json`:

```json
{
  "timers": {
    "short_break_interval": 600,      // 10 minutes (in seconds)
    "short_break_duration": 10,       // 10 seconds
    "long_break_interval": 3600,      // 1 hour (in seconds)
    "long_break_duration": 600,       // 10 minutes (in seconds)
    "postpone_duration": 300          // 5 minutes (in seconds)
  },
  "notifications": {
    "enabled": true,
    "sound_enabled": false,
    "warning_before_break": 30
  },
  "overlay": {
    "dim_screen": true,
    "dim_opacity": 0.8,
    "show_skip_button": true,
    "show_postpone_button": true,
    "theme": "dark"
  },
  "behavior": {
    "auto_start": true,
    "reset_on_idle": true,
    "idle_threshold": 300,
    "strict_mode": false
  }
}
```

### Configuration Options

**Timers:**
- `short_break_interval`: Time between short breaks (seconds)
- `short_break_duration`: Duration of short break (seconds)
- `long_break_interval`: Time between long breaks (seconds)
- `long_break_duration`: Duration of long break (seconds)
- `postpone_duration`: How long to postpone a break (seconds)

**Notifications:**
- `enabled`: Enable desktop notifications
- `sound_enabled`: Play sound with notifications (not implemented yet)
- `warning_before_break`: Warn X seconds before break

**Overlay:**
- `dim_screen`: Dim screen during break
- `dim_opacity`: Opacity of dim overlay (0.0-1.0)
- `show_skip_button`: Show skip button on overlay
- `show_postpone_button`: Show postpone button on overlay
- `theme`: Color theme (dark/light)

**Behavior:**
- `auto_start`: Start timer automatically on login
- `reset_on_idle`: Reset timer when system is idle (recommended: true)
- `idle_threshold`: Idle time in seconds before resetting timer (default: 300 = 5 min)
- `strict_mode`: Don't allow skipping breaks (not fully implemented)

## Usage

### Waybar Module

The timer appears in your Waybar with the following interactions:

- **Left Click**: Toggle pause/resume
- **Right Click**: Open settings menu
- **Middle Click**: Open interactive menu

### Display States

- **🕐 8:23** - Working (green) - 8 minutes 23 seconds until next break
- **⏸️ Paused** - Timer paused (gray)
- **⏸️ 0:08** - Short break (sky blue) - 8 seconds remaining
- **☕ 5:30** - Long break (peach) - 5 minutes 30 seconds remaining
- **⏲️** - Inactive (timer not running)

### Break Overlay Controls

When a break starts, a fullscreen overlay appears with:

- **Countdown timer**: Shows time remaining
- **Progress bar**: Visual progress indicator
- **Skip button**: Skip the current break
- **Postpone button**: Postpone break by 5 minutes (long breaks only)

**Keyboard shortcuts during break:**
- `ESC` or `s`: Skip break
- `p`: Postpone break (long breaks only)

### Command Line

```bash
# Control the timer
~/.config/hypr/scripts/WorkBreakTimerControl.sh start       # Start daemon
~/.config/hypr/scripts/WorkBreakTimerControl.sh stop        # Stop daemon
~/.config/hypr/scripts/WorkBreakTimerControl.sh toggle      # Pause/resume
~/.config/hypr/scripts/WorkBreakTimerControl.sh skip        # Skip current break
~/.config/hypr/scripts/WorkBreakTimerControl.sh postpone    # Postpone break
~/.config/hypr/scripts/WorkBreakTimerControl.sh settings    # Open settings
~/.config/hypr/scripts/WorkBreakTimerControl.sh menu        # Show menu

# Check status
~/.config/hypr/scripts/WorkBreakTimerStatus.sh

# View daemon logs
journalctl -f | grep WorkBreakTimer
```

## Starting the Timer

The timer starts automatically on login via Hyprland's `exec-once`.

To start manually:
```bash
python3 ~/.config/hypr/scripts/WorkBreakTimer.py daemon &
```

To stop:
```bash
pkill -f WorkBreakTimer.py
```

## Customization

### Change Break Intervals

Use the settings menu (right-click Waybar module) or edit config.json:

```bash
# 15 minute short breaks instead of 10
"short_break_interval": 900

# 2 hour long breaks instead of 1 hour
"long_break_interval": 7200
```

### Change Break Durations

```bash
# 20 second short breaks
"short_break_duration": 20

# 15 minute long breaks
"long_break_duration": 900
```

### Disable Skip/Postpone Buttons

```bash
"show_skip_button": false
"show_postpone_button": false
```

### Change Waybar Module Position

Edit `~/.config/waybar/config` and move `"custom/work_break_timer"` to desired location in modules-left, modules-center, or modules-right.

### Change Colors

The module uses Catppuccin colors by default. To change:

Edit `~/.config/waybar/style/[Catppuccin] Mocha Transparent.css`:

```css
#custom-work_break_timer.working {
  color: @green;  /* Change to @blue, @red, @yellow, etc. */
}
```

Available colors: `@red`, `@green`, `@blue`, `@yellow`, `@pink`, `@mauve`, `@teal`, `@sky`, `@sapphire`, `@lavender`, `@peach`

## Troubleshooting

### Timer not showing in Waybar

1. Check if daemon is running:
   ```bash
   pgrep -f WorkBreakTimer.py
   ```

2. Restart Waybar:
   ```bash
   killall -SIGUSR2 waybar
   ```

3. Check for errors:
   ```bash
   ~/.config/hypr/scripts/WorkBreakTimerStatus.sh
   ```

### Break overlay not appearing

1. Check if kitty terminal is installed:
   ```bash
   which kitty
   ```

2. Test overlay manually:
   ```bash
   ~/.config/hypr/scripts/BreakOverlay.sh short 10
   ```

3. Check Hyprland window rules:
   ```bash
   hyprctl clients | grep break-overlay
   ```

### Timer resets unexpectedly

Check if `reset_on_idle` is enabled in config. Disable it if you want timer to continue when away.

### Can't skip or postpone breaks

Check if buttons are enabled in config:
```json
"show_skip_button": true
"show_postpone_button": true
```

### Settings menu not working

Ensure `rofi` and `jq` are installed:
```bash
sudo pacman -S rofi jq
```

## Dependencies

- Python 3
- jq (for JSON parsing)
- rofi (for settings menu)
- kitty (for break overlay)
- notify-send (for notifications)
- Hyprland
- Waybar

Install missing dependencies:
```bash
sudo pacman -S python jq rofi kitty libnotify hyprland waybar
```

## Uninstalling

1. Remove autostart line from `~/.config/hypr/UserConfigs/Startup_Apps.conf`
2. Remove module from `~/.config/waybar/config`
3. Stop daemon: `pkill -f WorkBreakTimer.py`
4. Remove files:
   ```bash
   rm -rf ~/.config/work-break-timer
   rm ~/.config/hypr/scripts/WorkBreakTimer*
   rm ~/.config/hypr/scripts/BreakOverlay.sh
   ```
5. Remove CSS styling from Waybar theme (search for `#custom-work_break_timer`)

## Tips for Healthy Work Habits

- **Look away from screen**: Use break time to focus on distant objects (20-20-20 rule)
- **Stand and stretch**: Get up during long breaks to improve circulation
- **Hydrate**: Use breaks as reminders to drink water
- **Don't skip breaks**: They improve productivity and reduce eye strain
- **Adjust intervals**: Find what works for your workflow

## Support

For issues or suggestions:
- Check Hyprland logs: `hyprctl clients`
- Check Waybar logs: `journalctl --user -u waybar`
- Check daemon logs: Look for Python errors in system logs

## Credits

- Designed for Hyprland + Waybar setup
- Uses Catppuccin Mocha color scheme
- Inspired by Pomodoro technique and 20-20-20 rule

## License

Free to use and modify for personal use.

---

**Enjoy healthy work habits! 🎉**

# Work Break Timer - Installation Summary

## ✅ Successfully Installed!

Your Work Break Timer is now fully integrated into your Hyprland + Waybar setup.

---

## 🎯 What It Does

The timer tracks your active work time and automatically reminds you to take breaks:

- **Every 10 minutes** → 10-second short break (look away from screen)
- **Every 1 hour** → 10-minute long break (stand up, stretch)

### 🧠 Smart Features

1. **Idle Detection**: When you're away from your PC for more than 5 minutes, the timer resets
   - Only counts active work time
   - Won't interrupt you when you return from being away

2. **Fullscreen Breaks**: Beautiful terminal overlay with:
   - Animated countdown timer
   - Progress bar
   - Skip/postpone controls
   - Keyboard shortcuts (ESC or 's' to skip, 'p' to postpone)

3. **Waybar Integration**: See your next break countdown in real-time
   - 🕐 Green = Working
   - ⏸️ Gray = Paused
   - ⏸️ Sky blue = Short break
   - ☕ Peach = Long break

---

## 🚀 Quick Start

### Check Status

The timer is already running! Look at your Waybar - you should see a countdown timer.

```bash
# Check if daemon is running
pgrep -f WorkBreakTimer.py

# View current status
~/.config/hypr/scripts/WorkBreakTimerStatus.sh
```

### Control the Timer

**Via Waybar:**
- Left-click: Pause/Resume
- Right-click: Settings menu
- Middle-click: Full control menu

**Via Command Line:**
```bash
# Pause/resume timer
~/.config/hypr/scripts/WorkBreakTimerControl.sh toggle

# Open settings menu
~/.config/hypr/scripts/WorkBreakTimerControl.sh settings

# View all options
~/.config/hypr/scripts/WorkBreakTimerControl.sh menu
```

---

##  ⚙️ Configuration

Edit: `~/.config/work-break-timer/config.json`

### Common Customizations

**Change break intervals:**
```json
"short_break_interval": 900,    // 15 minutes instead of 10
"long_break_interval": 7200,    // 2 hours instead of 1 hour
```

**Change break durations:**
```json
"short_break_duration": 20,     // 20 seconds instead of 10
"long_break_duration": 900,     // 15 minutes instead of 10
```

**Adjust idle detection:**
```json
"reset_on_idle": true,          // Enable/disable idle detection
"idle_threshold": 300,          // Time in seconds (5 min = 300)
```

**Disable skip/postpone:**
```json
"show_skip_button": false,
"show_postpone_button": false
```

After making changes, restart the daemon:
```bash
pkill -f WorkBreakTimer.py
python3 ~/.config/hypr/scripts/WorkBreakTimer.py daemon &
```

---

## 🎮 During a Break

When a break starts, a fullscreen terminal overlay appears:

**Keyboard Shortcuts:**
- `ESC` or `s` = Skip break
- `p` = Postpone break by 5 minutes (long breaks only)

The overlay shows:
- Large countdown timer
- Progress bar
- Instructions
- Motivational tip

---

## 🔧 Troubleshooting

### Timer not visible in Waybar

```bash
# Reload Waybar
killall -SIGUSR2 waybar

# Or restart Waybar completely
pkill waybar && waybar &
```

### Breaks not triggering

```bash
# Check if timer is paused
cat ~/.config/work-break-timer/state.json | jq '.paused'

# Resume if paused
~/.config/hypr/scripts/WorkBreakTimerControl.sh toggle
```

### Overlay not appearing

```bash
# Test overlay manually
~/.config/hypr/scripts/BreakOverlay.sh short 5

# Check if kitty is installed
which kitty
```

### Timer keeps resetting

The idle detection is working! If you don't want this:

```json
"reset_on_idle": false
```

---

## 📊 Statistics

View your break statistics:

```bash
# Via settings menu
~/.config/hypr/scripts/WorkBreakTimerControl.sh settings
# Then select "View statistics"

# Or check state file
cat ~/.config/work-break-timer/state.json | jq '.breaks_taken'
```

---

## 📁 File Locations

**Config & Data:**
- Config: `~/.config/work-break-timer/config.json`
- State: `~/.config/work-break-timer/state.json`
- README: `~/.config/work-break-timer/README.md`

**Scripts:**
- Daemon: `~/.config/hypr/scripts/WorkBreakTimer.py`
- Status: `~/.config/hypr/scripts/WorkBreakTimerStatus.sh`
- Control: `~/.config/hypr/scripts/WorkBreakTimerControl.sh`
- Overlay: `~/.config/hypr/scripts/BreakOverlay.sh`

**Integration:**
- Waybar config: `~/.config/waybar/config`
- Waybar module: `~/.config/waybar/ModulesCustom`
- Waybar style: `~/.config/waybar/style/[Catppuccin] Mocha Transparent.css`
- Autostart: `~/.config/hypr/UserConfigs/Startup_Apps.conf`

---

## 🎯 Recommended Settings

For optimal eye health and productivity:

1. **20-20-20 Rule Compatible:**
   ```json
   "short_break_interval": 1200,  // 20 minutes
   "short_break_duration": 20,    // 20 seconds
   ```

2. **Pomodoro Technique:**
   ```json
   "short_break_interval": 1500,  // 25 minutes
   "short_break_duration": 300,   // 5 minutes
   "long_break_interval": 7200,   // 2 hours (4 pomodoros)
   "long_break_duration": 900,    // 15 minutes
   ```

3. **Office Worker:**
   ```json
   "short_break_interval": 600,   // 10 minutes (default)
   "short_break_duration": 10,    // 10 seconds (quick reminder)
   "long_break_interval": 3600,   // 1 hour (default)
   "long_break_duration": 600,    // 10 minutes
   ```

---

## 💡 Tips

1. **Don't skip breaks**: They actually improve productivity!
2. **Use long breaks to move**: Stand, walk, stretch
3. **Use short breaks for eyes**: Look at something 20 feet away
4. **Stay hydrated**: Use breaks as water reminders
5. **Customize to your workflow**: Adjust intervals as needed

---

## 🆘 Need Help?

Full documentation: `~/.config/work-break-timer/README.md`

Or run:
```bash
~/.config/hypr/scripts/WorkBreakTimerControl.sh --help
```

---

**Enjoy healthy work habits! 🎉**

Your future self will thank you for taking care of your eyes and body!

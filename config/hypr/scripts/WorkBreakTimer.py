#!/usr/bin/env python3
"""
Work Break Timer Daemon
Manages work/break cycles with short and long breaks
"""

import json
import os
import sys
import time
import signal
import subprocess
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, Optional

class WorkBreakTimer:
    def __init__(self):
        self.config_dir = Path.home() / ".config" / "hypr" / "work-break-timer"
        self.config_file = self.config_dir / "config.json"
        self.state_file = self.config_dir / "state.json"
        self.socket_file = self.config_dir / "timer.sock"

        self.config = self.load_config()
        self.state = self.load_state()

        self.running = True
        self.paused = False

        # Idle tracking
        self.last_activity_check = time.time()
        self.last_input_events = self.get_input_events()

        # Setup signal handlers
        signal.signal(signal.SIGTERM, self.handle_signal)
        signal.signal(signal.SIGINT, self.handle_signal)

    def load_config(self) -> Dict:
        """Load configuration from JSON file"""
        try:
            with open(self.config_file, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            print(f"Config file not found: {self.config_file}")
            sys.exit(1)
        except json.JSONDecodeError as e:
            print(f"Invalid JSON in config: {e}")
            sys.exit(1)

    def load_state(self) -> Dict:
        """Load or initialize timer state"""
        if self.state_file.exists():
            try:
                with open(self.state_file, 'r') as f:
                    return json.load(f)
            except (json.JSONDecodeError, FileNotFoundError):
                pass

        # Initialize default state
        now = time.time()
        return {
            "last_short_break": now,
            "last_long_break": now,
            "work_start": now,
            "paused": False,
            "paused_at": None,
            "pause_remaining": 0,
            "in_break": False,
            "break_type": None,
            "break_end": None,
            "total_work_time": 0,
            "breaks_taken": {
                "short": 0,
                "long": 0
            }
        }

    def save_state(self):
        """Save current state to file"""
        self.state["paused"] = self.paused
        with open(self.state_file, 'w') as f:
            json.dump(self.state, f, indent=2)

    def handle_signal(self, signum, frame):
        """Handle shutdown signals"""
        print("\nShutting down Work Break Timer...")
        self.running = False
        self.save_state()
        sys.exit(0)

    def notify(self, title: str, message: str, urgency: str = "normal"):
        """Send desktop notification"""
        if not self.config["notifications"]["enabled"]:
            return

        try:
            subprocess.run([
                "notify-send",
                "-u", urgency,
                "-i", "appointment-soon",
                "-a", "Work Break Timer",
                title,
                message
            ], check=False)
        except FileNotFoundError:
            pass

    def show_break_overlay(self, break_type: str, duration: int):
        """Show fullscreen break overlay"""
        overlay_script = Path.home() / ".config" / "hypr" / "scripts" / "BreakOverlay.sh"
        subprocess.Popen([
            str(overlay_script),
            break_type,
            str(duration)
        ], start_new_session=True)

    def get_input_events(self) -> int:
        """Get total input events from /proc/interrupts (keyboard + mouse)"""
        total = 0
        try:
            with open('/proc/interrupts', 'r') as f:
                for line in f:
                    # Look for keyboard and mouse interrupts
                    if 'i8042' in line or 'keyboard' in line.lower() or 'mouse' in line.lower():
                        parts = line.split()
                        # Sum all CPU columns (skip first column which is IRQ number)
                        for part in parts[1:]:
                            try:
                                total += int(part)
                            except ValueError:
                                break
        except:
            pass
        return total

    def is_user_active(self) -> bool:
        """Check if user is currently active"""
        # Check if idle detection is enabled
        if not self.config.get("behavior", {}).get("reset_on_idle", True):
            return True  # Always active if idle detection is disabled

        current_events = self.get_input_events()
        is_active = current_events != self.last_input_events
        self.last_input_events = current_events

        return is_active

    def get_time_until_next_break(self) -> tuple[str, int]:
        """Get type and seconds until next break"""
        if self.paused or self.state["in_break"]:
            return "paused" if self.paused else self.state["break_type"], 0

        now = time.time()
        short_interval = self.config["timers"]["short_break_interval"]
        long_interval = self.config["timers"]["long_break_interval"]

        time_since_short = now - self.state["last_short_break"]
        time_since_long = now - self.state["last_long_break"]

        time_until_short = short_interval - time_since_short
        time_until_long = long_interval - time_since_long

        # Next break is whichever comes first
        if time_until_short <= time_until_long:
            return "short", max(0, int(time_until_short))
        else:
            return "long", max(0, int(time_until_long))

    def format_time(self, seconds: int) -> str:
        """Format seconds into readable time"""
        if seconds < 60:
            return f"{seconds}s"
        elif seconds < 3600:
            mins = seconds // 60
            secs = seconds % 60
            return f"{mins}:{secs:02d}"
        else:
            hours = seconds // 3600
            mins = (seconds % 3600) // 60
            return f"{hours}:{mins:02d}"

    def trigger_break(self, break_type: str):
        """Trigger a break"""
        duration = (self.config["timers"]["short_break_duration"]
                   if break_type == "short"
                   else self.config["timers"]["long_break_duration"])

        self.state["in_break"] = True
        self.state["break_type"] = break_type
        self.state["break_end"] = time.time() + duration
        self.save_state()

        # Send notification
        break_name = "Short Break" if break_type == "short" else "Long Break"
        duration_str = f"{duration}s" if duration < 60 else f"{duration//60}min"
        self.notify(
            f"Time for a {break_name}!",
            f"Take a {duration_str} break. Your eyes and body will thank you!",
            "critical"
        )

        # Show overlay
        self.show_break_overlay(break_type, duration)

        # Update break tracking
        self.state["breaks_taken"][break_type] += 1

    def end_break(self):
        """End current break"""
        now = time.time()
        break_type = self.state["break_type"]

        if break_type == "short":
            self.state["last_short_break"] = now
        elif break_type == "long":
            self.state["last_long_break"] = now

        self.state["in_break"] = False
        self.state["break_type"] = None
        self.state["break_end"] = None
        self.save_state()

        self.notify("Break Over", "Back to work! Stay focused.")

    def skip_break(self):
        """Skip current break"""
        if self.state["in_break"]:
            # Kill overlay
            subprocess.run(["pkill", "-f", "BreakOverlay.sh"], check=False)
            self.end_break()

    def postpone_break(self):
        """Postpone current or upcoming break"""
        postpone_duration = self.config["timers"]["postpone_duration"]

        if self.state["in_break"]:
            # Skip current break and postpone
            self.skip_break()

        # Postpone next break
        now = time.time()
        self.state["last_short_break"] = now - (
            self.config["timers"]["short_break_interval"] - postpone_duration
        )
        self.save_state()

        self.notify(
            "Break Postponed",
            f"Break postponed for {postpone_duration//60} minutes"
        )

    def toggle_pause(self):
        """Toggle pause state"""
        self.paused = not self.paused
        self.state["paused"] = self.paused

        if self.paused:
            self.state["paused_at"] = time.time()
            self.notify("Timer Paused", "Work break timer is paused")
        else:
            # Adjust timers by the paused duration
            if self.state["paused_at"]:
                pause_duration = time.time() - self.state["paused_at"]
                self.state["last_short_break"] += pause_duration
                self.state["last_long_break"] += pause_duration
                self.state["paused_at"] = None
            self.notify("Timer Resumed", "Work break timer is active")

        self.save_state()

    def run(self):
        """Main daemon loop"""
        print("Work Break Timer daemon started")
        self.notify("Work Break Timer Started", "Timer is now active")

        idle_start = None
        idle_threshold = self.config.get("behavior", {}).get("idle_threshold", 300)

        while self.running:
            try:
                # Check for marker files (pause, skip, postpone commands)
                pause_marker = self.config_dir / "pause.marker"
                skip_marker = self.config_dir / "skip.marker"
                postpone_marker = self.config_dir / "postpone.marker"

                if pause_marker.exists():
                    pause_marker.unlink()
                    self.toggle_pause()

                if skip_marker.exists():
                    skip_marker.unlink()
                    self.skip_break()

                if postpone_marker.exists():
                    postpone_marker.unlink()
                    self.postpone_break()

                if not self.paused:
                    now = time.time()

                    # Check user activity
                    is_active = self.is_user_active()

                    # Handle idle detection for timer reset
                    if not is_active:
                        if idle_start is None:
                            idle_start = now
                        elif (now - idle_start) > idle_threshold:
                            # User has been idle too long - reset short break timer only
                            # This prevents interrupting the user when they return from being away
                            if not self.state["in_break"]:
                                self.state["last_short_break"] = now
                                # Only reset long break if it would have triggered
                                time_since_long = now - self.state["last_long_break"]
                                if time_since_long >= self.config["timers"]["long_break_interval"]:
                                    self.state["last_long_break"] = now
                                self.save_state()
                                # Reset idle_start to avoid repeated resets
                                idle_start = now
                    else:
                        idle_start = None

                    # Check if in break
                    if self.state["in_break"]:
                        if now >= self.state["break_end"]:
                            self.end_break()
                    else:
                        # Check for breaks - allow if user hasn't been idle too long
                        # Only skip triggering if idle > threshold (to avoid interrupting when truly away)
                        can_trigger = (idle_start is None) or ((now - idle_start) <= idle_threshold)

                        if can_trigger:
                            short_interval = self.config["timers"]["short_break_interval"]
                            long_interval = self.config["timers"]["long_break_interval"]

                            time_since_short = now - self.state["last_short_break"]
                            time_since_long = now - self.state["last_long_break"]

                            # Trigger breaks
                            if time_since_long >= long_interval:
                                self.trigger_break("long")
                            elif time_since_short >= short_interval:
                                self.trigger_break("short")

                # Sleep for 1 second
                time.sleep(1)

            except Exception as e:
                print(f"Error in main loop: {e}")
                time.sleep(5)

    def get_status(self) -> Dict:
        """Get current status for display"""
        if self.paused:
            return {
                "state": "paused",
                "text": "⏸ Paused",
                "next_break": None,
                "time_until": None
            }

        if self.state["in_break"]:
            remaining = int(self.state["break_end"] - time.time())
            break_type = self.state["break_type"]
            return {
                "state": f"break_{break_type}",
                "text": f"☕ Break: {self.format_time(remaining)}",
                "next_break": break_type,
                "time_until": remaining
            }

        break_type, seconds = self.get_time_until_next_break()
        return {
            "state": "working",
            "text": f"🕐 {self.format_time(seconds)}",
            "next_break": break_type,
            "time_until": seconds
        }

def main():
    if len(sys.argv) > 1:
        command = sys.argv[1]
        state_file = Path.home() / ".config" / "hypr" / "work-break-timer" / "state.json"

        # Handle commands
        if command == "status":
            # Read state and print status
            timer = WorkBreakTimer()
            status = timer.get_status()
            print(json.dumps(status))
        elif command == "skip":
            # Send skip signal
            subprocess.run(["pkill", "-f", "BreakOverlay.sh"], check=False)
        elif command == "postpone":
            # Create postpone marker file
            marker = Path.home() / ".config" / "hypr" / "work-break-timer" / "postpone.marker"
            marker.touch()
        elif command == "pause":
            # Create pause marker file
            marker = Path.home() / ".config" / "hypr" / "work-break-timer" / "pause.marker"
            marker.touch()
        elif command == "daemon":
            # Run as daemon
            timer = WorkBreakTimer()
            timer.run()
        else:
            print(f"Unknown command: {command}")
            sys.exit(1)
    else:
        # Default: run as daemon
        timer = WorkBreakTimer()
        timer.run()

if __name__ == "__main__":
    main()

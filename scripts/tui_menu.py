#!/usr/bin/env python3
# Simple TUI menu for Hyprland-Dots copy workflow
# - Prefers Textual (rich) for a nicer UI with mouse + keyboard
# - Falls back to curses if Textual is unavailable
# - Prints the chosen action (Install|Upgrade|Express|Update|Quit) to stdout

from __future__ import annotations

import argparse
import os
import sys

CHOICES = [
    ("Install", "Fresh copy of the dotfiles into ~/.config"),
    ("Upgrade", "Backups + interactive prompts"),
    ("Express", "Skips restore prompts and large wallpaper download"),
    ("Update", "Update this repo: stash local changes, git pull"),
    ("Help", "Explain the options shown here"),
    ("Quit", "Exit without making changes"),
]

HELP_TEXT = (
    "Install: Perform a fresh copy of configs into ~/.config.\n"
    "Upgrade: Back up existing configs and prompt to restore what you want.\n"
    "Express: Faster upgrade (requires installed dots >= the minimum version).\n"
    "Update: Safely update this Git repo (stash local changes, then git pull).\n"
    "Quit: Exit without making changes.\n\n"
    "Tips:\n"
    "- Use Up/Down or mouse to select, Enter to confirm.\n"
    "- Press the highlighted first letter (I/U/E/U/Q/H) as a shortcut.\n"
    "- Press h or ? at any time to view this help.\n"
)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--express-supported", default="0", choices=["0", "1"], help="Whether Express is allowed (1) or not (0)")
    parser.add_argument("--backend", default=os.environ.get("COPY_TUI_BACKEND", "auto"), choices=["auto", "textual", "curses", "basic"], help="Choose UI backend")
    args = parser.parse_args()
    express_supported = args.express_supported == "1"
    backend = args.backend

    if backend == "textual":
        return run_textual(express_supported)
    if backend == "curses":
        return run_curses(express_supported)
    if backend == "basic":
        return run_basic(express_supported)

    # auto: Try Textual, then curses, then basic
    try:
        return run_textual(express_supported)
    except Exception:
        pass
    try:
        return run_curses(express_supported)
    except Exception:
        return run_basic(express_supported)


def stylize_first_letter(label: str) -> tuple[str, str]:
    # returns (styled_label_for_ui, hotkey)
    hotkey = label[0].upper()
    rest = label[1:]
    # Textual Rich markup: bold + accent color for the first letter
    styled = f"[b][cyan]{hotkey}[/cyan][/b]{rest}"
    return styled, hotkey


def run_textual(express_supported: bool) -> int:
    from textual.app import App, ComposeResult
    from textual.widgets import Header, Footer, Static, Button
    from textual.containers import Vertical
    from textual.reactive import reactive
    from textual import events

    class MenuButton(Button):
        def __init__(self, label: str, choice_key: str, disabled: bool = False) -> None:
            super().__init__(label, disabled=disabled)
            self.choice_key = choice_key

    class MenuApp(App):
        CSS = """
        Screen { background: black; }
        #title { content-align: center middle; height: 3; color: white; }
        Vertical { width: 80; max-width: 90; margin: 1 auto; }
        Button { margin: 1 0; padding: 1 2; border: round cornflowerblue; }
        Button:hover { background: rgba(100,100,255,0.1); }
        Button.-disabled { color: grey50; border: round grey35; }
        #help { padding: 1 2; border: round grey42; height: auto; }
        """

        selected: reactive[str | None] = reactive(None)

        def compose(self) -> ComposeResult:  # type: ignore[override]
            yield Header(show_clock=False)
            yield Static("KooL's Hyprland Dotfiles", id="title")
            with Vertical():
                # Build buttons
                for (name, _desc) in CHOICES:
                    if name == "Express" and not express_supported:
                        styled, _hk = stylize_first_letter(name)
                        yield MenuButton(f"{styled}  [grey62](requires newer installed dots)\n[/grey62]", name, disabled=True)
                    else:
                        styled, _hk = stylize_first_letter(name)
                        yield MenuButton(styled, name)
                yield Static("Press h or ? for help", id="help")
            yield Footer()

        def on_button_pressed(self, event: Button.Pressed) -> None:  # type: ignore[override]
            btn = event.button
            if isinstance(btn, MenuButton):
                if btn.choice_key == "Help":
                    self.show_help()
                    return
                if btn.choice_key == "Express" and not express_supported:
                    return
                self.selected = btn.choice_key
                self.exit_app()

        def action_quit(self) -> None:  # Esc
            self.exit_app("Quit")

        BINDINGS = [
            ("escape", "quit", "Quit"),
            ("i", "select('Install')", "Install"),
            ("u", "select('Upgrade')", "Upgrade"),
            ("e", "select('Express')", "Express"),
            ("d", "select('Update')", "Update"),
            ("q", "select('Quit')", "Quit"),
            ("h", "help", "Help"),
            ("?", "help", "Help"),
            ("enter", "activate", "Select"),
        ]

        def action_select(self, name: str) -> None:
            if name == "Express" and not express_supported:
                return
            if name == "Help":
                self.show_help()
                return
            self.selected = name
            self.exit_app()

        def action_help(self) -> None:
            self.show_help()

        def action_activate(self) -> None:
            # Activate focused button
            focused = self.focused
            if isinstance(focused, MenuButton):
                self.on_button_pressed(Button.Pressed(focused))

        def show_help(self) -> None:
            self.push_screen(HelpScreen())

        def exit_app(self, fallback: str | None = None) -> None:
            result = self.selected or fallback
            if result:
                print(result)
            self.exit(0)

    from textual.screen import ModalScreen

    class HelpScreen(ModalScreen[None]):
        def compose(self) -> ComposeResult:  # type: ignore[override]
            yield Static("[b]Help[/b]\n\n" + HELP_TEXT, id="help")

        BINDINGS = [("escape", "dismiss", "Close"), ("q", "dismiss", "Close")]

        def action_dismiss(self) -> None:
            self.dismiss(None)

    app = MenuApp()
    app.run()
    return 0


def run_curses(express_supported: bool) -> int:
    import curses

    labels = [name for (name, _d) in CHOICES]

    def draw_menu(stdscr, idx: int, show_help: bool) -> None:
        stdscr.clear()
        h, w = stdscr.getmaxyx()
        title = "KooL's Hyprland Dotfiles"
        stdscr.attron(curses.A_BOLD)
        stdscr.addstr(1, max(2, (w - len(title)) // 2), title)
        stdscr.attroff(curses.A_BOLD)

        y = 4
        for i, name in enumerate(labels):
            disabled = (name == "Express" and not express_supported)
            hk = name[0].upper()
            rest = name[1:]
            if i == idx:
                stdscr.attron(curses.A_REVERSE)
            # First letter styled
            stdscr.attron(curses.color_pair(1) | curses.A_BOLD)
            stdscr.addstr(y, 4, hk)
            stdscr.attroff(curses.color_pair(1) | curses.A_BOLD)
            if disabled:
                stdscr.attron(curses.A_DIM)
            stdscr.addstr(y, 5, rest)
            if disabled:
                msg = "  (requires newer installed dots)"
                stdscr.addstr(y, 5 + len(rest), msg, curses.A_DIM)
                stdscr.attroff(curses.A_DIM)
            if i == idx:
                stdscr.attroff(curses.A_REVERSE)
            y += 2

        info = "Enter=Select  Up/Down=Move  Mouse=Click  h/?=Help  q=Quit"
        stdscr.addstr(h - 2, 2, info[: max(0, w - 4)])

        if show_help:
            box_w = min(w - 6, 76)
            box_h = min(12, h - 6)
            bx = max(2, (w - box_w) // 2)
            by = max(2, (h - box_h) // 2)
            for yy in range(by, by + box_h):
                stdscr.addstr(yy, bx, " " * max(0, box_w), curses.color_pair(3))
            stdscr.attron(curses.A_BOLD)
            stdscr.addstr(by, bx + 2, "Help")
            stdscr.attroff(curses.A_BOLD)
            for i, line in enumerate(HELP_TEXT.splitlines()[: max(0, box_h - 3)]):
                stdscr.addstr(by + 2 + i, bx + 2, line[: max(0, box_w - 4)])
            stdscr.addstr(by + box_h - 2, bx + 2, "Press q or Esc to close help")

        stdscr.refresh()

    def loop(stdscr) -> str:
        curses.curs_set(0)
        curses.mousemask(1)
        curses.start_color()
        try:
            curses.use_default_colors()
        except Exception:
            pass
        try:
            curses.init_pair(1, curses.COLOR_CYAN, -1)
        except Exception:
            curses.init_pair(1, curses.COLOR_CYAN, 0)
        try:
            curses.init_pair(3, curses.COLOR_WHITE, curses.COLOR_BLUE)
        except Exception:
            curses.init_pair(3, curses.COLOR_WHITE, 0)
        idx = 0
        showing_help = False

        while True:
            draw_menu(stdscr, idx, showing_help)
            ch = stdscr.getch()
            if showing_help:
                if ch in (ord('q'), ord('Q'), 27):
                    showing_help = False
                continue

            if ch in (curses.KEY_UP, ord('k')):
                idx = (idx - 1) % len(labels)
            elif ch in (curses.KEY_DOWN, ord('j')):
                idx = (idx + 1) % len(labels)
            elif ch in (ord('h'), ord('?')):
                showing_help = True
            elif ch in (ord('q'), 27):
                return "Quit"
            elif ch == curses.KEY_MOUSE:
                try:
                    _, mx, my, _, _ = curses.getmouse()
                    base_y = 4
                    if my >= base_y:
                        clicked = (my - base_y) // 2
                        if 0 <= clicked < len(labels):
                            name = labels[clicked]
                            if name == "Help":
                                showing_help = True
                            elif name == "Express" and not express_supported:
                                pass
                            else:
                                return name
                except Exception:
                    pass
            elif ch in (curses.KEY_ENTER, 10, 13):
                name = labels[idx]
                if name == "Help":
                    showing_help = True
                elif name == "Express" and not express_supported:
                    pass
                else:
                    return name
            else:
                try:
                    key = chr(ch).lower() if 0 <= ch < 256 else ""
                except Exception:
                    key = ""
                mapping = {"i": "Install", "u": "Upgrade", "e": "Express", "d": "Update", "q": "Quit", "h": "Help"}
                if key in mapping:
                    name = mapping[key]
                    if name == "Help":
                        showing_help = True
                    elif name == "Express" and not express_supported:
                        pass
                    else:
                        return name

    choice = curses.wrapper(loop)
    print(choice)
    return 0


def run_basic(express_supported: bool) -> int:
    # Minimal stdin-only fallback
    options = [n for (n, _d) in CHOICES]
    while True:
        print("Select:")
        for i, name in enumerate(options, 1):
            if name == "Express" and not express_supported:
                print(f"  {i}) {name} (disabled)")
            else:
                print(f"  {i}) {name}")
        try:
            sel = input("> ").strip()
        except EOFError:
            print("Quit")
            return 0
        if sel.isdigit():
            idx = int(sel) - 1
            if 0 <= idx < len(options):
                choice = options[idx]
                if choice == "Express" and not express_supported:
                    continue
                if choice == "Help":
                    print(HELP_TEXT)
                    continue
                print(choice)
                return 0

if __name__ == "__main__":
    sys.exit(main())

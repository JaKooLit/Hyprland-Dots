from __future__ import annotations

from textual import events
from textual.containers import Container
from textual.screen import Screen
from textual.widgets import Button, Static

from dots_tui.screens.config import ConfigScreen
from dots_tui.screens.confirm import ConfirmScreen
from dots_tui.screens.progress import ProgressScreen


class MenuScreen(Screen[None]):
    def __init__(self, *, dry_run: bool = False) -> None:
        super().__init__()
        self._express_supported: bool = False
        self._dry_run = dry_run

    BINDINGS = [
        ("j", "down", "Down"),
        ("down", "down", "Down"),
        ("k", "up", "Up"),
        ("up", "up", "Up"),
        ("h", "app.quit", "Quit"),
        ("q", "app.quit", "Quit"),
        ("escape", "app.quit", "Quit"),
        ("right", "activate", "Select"),
        ("enter", "activate", "Select"),
        ("space", "activate", "Select"),
    ]

    def on_mount(self) -> None:
        express_btn = self.query_one("#express", Button)
        express_btn.disabled = True
        express_btn.label = "Express (checking...)"

        async def apply_probe() -> None:
            get_probe = getattr(self.app, "get_probe")
            probe = await get_probe()
            self._express_supported = probe.express_supported
            # Guard against screen being exited before probe completes.
            try:
                if self._express_supported:
                    express_btn.disabled = False
                    express_btn.label = "Express"
                else:
                    express_btn.disabled = True
                    express_btn.label = "Express (disabled)"
            except Exception:
                # Screen was likely unmounted; ignore widget updates.
                pass

        self.run_worker(apply_probe, exclusive=True)

        # Ensure keyboard navigation starts on the first button.
        self.query_one(Button).focus()

    def action_down(self) -> None:
        self.app.action_focus_next()

    def action_up(self) -> None:
        self.app.action_focus_previous()

    def action_activate(self) -> None:
        focused = self.app.focused
        if isinstance(focused, Button):
            focused.press()

    def on_key(self, event: events.Key) -> None:
        if event.key in {"j", "down"}:
            self.app.action_focus_next()
            event.stop()
            return
        if event.key in {"k", "up"}:
            self.app.action_focus_previous()
            event.stop()
            return
        if event.key in {"l", "right", "enter", "space"}:
            self.action_activate()
            event.stop()
            return

    def compose(self):
        yield Container(
            Static("KooL's Hyprland-Dots", id="title"),
            Button("Install", id="install", variant="success"),
            Button("Upgrade", id="upgrade"),
            Button("Express", id="express"),
            Button("Update Repo", id="update"),
            Button("Quit", id="quit", variant="error"),
            Static("hjkl/arrows/tab: nav • space: select • q: quit", id="help"),
            id="menu",
        )

    def on_button_pressed(self, event: Button.Pressed) -> None:
        match event.button.id:
            case "install":
                self.app.push_screen(
                    ConfigScreen(run_mode="install", dry_run=self._dry_run)
                )
            case "upgrade":
                self.app.push_screen(
                    ConfigScreen(run_mode="upgrade", dry_run=self._dry_run)
                )
            case "express":

                def on_confirm(ok: bool | None) -> None:
                    if ok:
                        self.app.push_screen(
                            ConfigScreen(run_mode="express", dry_run=self._dry_run)
                        )

                msg = (
                    "Express Mode actions:\n"
                    "• Auto-accept restore & cleanup prompts\n"
                    "• Skip extra wallpaper downloads\n"
                    "• Skip SDDM wallpaper prompt\n\n"
                    "Proceed with Express Upgrade?"
                )
                self.app.push_screen(
                    ConfirmScreen(
                        message=msg, yes="Start Express", no="Cancel", default_yes=True
                    ),
                    on_confirm,
                )
            case "update":
                self.app.push_screen(ProgressScreen.for_repo_update())
            case "quit":
                self.app.exit()

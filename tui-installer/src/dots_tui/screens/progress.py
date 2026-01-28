from __future__ import annotations

from dataclasses import dataclass
import threading
from typing import Callable
from pathlib import Path

from textual import events, work
from textual.containers import Container
from textual.screen import Screen
from textual.widgets import Button, Label, Log, ProgressBar, Static

from dots_tui.utils import _sanitize_for_tui
from dots_tui.logic.models import InstallConfig
from dots_tui.logic.orchestrator import InstallerOrchestrator
from dots_tui.screens.confirm import ConfirmScreen


LogFn = Callable[[str], None]


@dataclass(frozen=True)
class ProgressTask:
    kind: str  # install|update
    config: InstallConfig | None = None


class ProgressScreen(Screen[None]):
    BINDINGS = [
        ("h", "scroll_left", "Left"),
        ("j", "scroll_down", "Down"),
        ("k", "scroll_up", "Up"),
        ("l", "scroll_right", "Right"),
        ("left", "scroll_left", "Left"),
        ("down", "scroll_down", "Down"),
        ("up", "scroll_up", "Up"),
        ("right", "scroll_right", "Right"),
        ("g,home", "scroll_home", "Top"),
        ("G,end", "scroll_end", "Bottom"),
    ]

    def __init__(self, *, task: ProgressTask) -> None:
        super().__init__()
        self._progress_task = task

    @classmethod
    def for_install(cls, config: InstallConfig) -> "ProgressScreen":
        return cls(task=ProgressTask(kind="install", config=config))

    @classmethod
    def for_repo_update(cls) -> "ProgressScreen":
        return cls(task=ProgressTask(kind="update"))

    def compose(self):
        yield Container(
            Static("Execution", id="title"),
            Label("", id="step"),
            ProgressBar(total=100, id="bar"),
            Log(id="log", highlight=False),
            Button("Back to Menu", id="back", classes="hidden"),
            Static("hjkl/arrows: scroll log ", id="help"),
            id="progress-container",
        )

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "back":
            self.app.pop_screen()

    def on_key(self, event: events.Key) -> None:
        if event.key == "space":
            focused = self.app.focused
            if isinstance(focused, Button):
                focused.press()
                event.stop()

    def on_mount(self) -> None:
        self.query_one(Log).max_lines = 5000
        self.query_one("#back", Button).display = False
        _ = self._run()

    def _is_main_thread(self) -> bool:
        """Check if we're running on Textual's main thread.

        NOTE: This uses Textual's internal `_thread_id` attribute which is not
        part of the public API. If Textual updates break this, look for an
        official API or update to use `App.is_main_thread()` if it becomes
        available. This is used to determine whether to call widget methods
        directly or via `call_from_thread()`.

        https://textual.textualize.io/api/app/#textual.app.App.call_from_thread
        """
        return self.app._thread_id == threading.get_ident()

    def _ui_log(self, message: str) -> None:
        """Write a line to the log widget (thread-safe)."""
        line = _sanitize_for_tui(message)
        log = self.query_one("#log", Log)
        if self._is_main_thread():
            log.write_line(line)
        else:
            self.app.call_from_thread(log.write_line, line)

    def action_scroll_down(self) -> None:
        self.query_one("#log", Log).action_scroll_down()

    def action_scroll_up(self) -> None:
        self.query_one("#log", Log).action_scroll_up()

    def action_scroll_home(self) -> None:
        self.query_one("#log", Log).action_scroll_home()

    def action_scroll_end(self) -> None:
        self.query_one("#log", Log).action_scroll_end()

    def action_scroll_left(self) -> None:
        self.query_one("#log", Log).action_scroll_left()

    def action_scroll_right(self) -> None:
        self.query_one("#log", Log).action_scroll_right()

    def _set_step(self, text: str, percent: int | None = None) -> None:
        """Update the step label and progress bar (thread-safe)."""
        step = self.query_one("#step", Label)
        bar = self.query_one("#bar", ProgressBar)
        if self._is_main_thread():
            step.update(text)
        else:
            self.app.call_from_thread(step.update, text)
        if percent is not None:
            if self._is_main_thread():
                setattr(bar, "progress", percent)
            else:
                self.app.call_from_thread(setattr, bar, "progress", percent)

    def _show_back_button(self) -> None:
        """Show the back button (thread-safe)."""
        btn = self.query_one("#back", Button)
        if self._is_main_thread():
            btn.display = True
        else:
            self.app.call_from_thread(setattr, btn, "display", True)

    def _prompt_confirm(
        self,
        message: str,
        yes: str = "Yes",
        no: str = "No",
        default_yes: bool = True,
    ) -> bool:
        """Ask a yes/no question via ConfirmScreen.

        This blocks only the worker thread (ProgressScreen._run), keeping the UI
        responsive.
        """

        ev = threading.Event()
        result: dict[str, bool] = {"value": default_yes}

        def on_answer(ok: bool | None) -> None:
            result["value"] = ok is True
            ev.set()

        def push() -> None:
            self.app.push_screen(
                ConfirmScreen(
                    message=message,
                    yes=yes,
                    no=no,
                    default_yes=default_yes,
                ),
                callback=on_answer,
            )

        if self.app._thread_id == threading.get_ident():
            push()
        else:
            self.app.call_from_thread(push)
        ev.wait()
        return result["value"]

    def _prompt_password(self, label: str) -> str | None:
        """Ask for a password via InputModal.
        Blocks the worker thread until answer is received.
        """
        from dots_tui.screens.input import InputModal

        ev = threading.Event()
        result: dict[str, str | None] = {"value": None}

        def on_answer(value: str | None) -> None:
            result["value"] = value
            ev.set()

        def push() -> None:
            self.app.push_screen(
                InputModal(
                    title="Authentication Required",
                    prompt=label,
                    password=True,
                    placeholder="Password",
                ),
                callback=on_answer,
            )

        if self._is_main_thread():
            push()
        else:
            self.app.call_from_thread(push)
        ev.wait()
        return result["value"]

    def _prompt_replace(self, name: str, path: Path) -> bool:
        msg = (
            f"Found existing {name} config at:\n"
            f"{path}\n\n"
            "Replace it? A backup will be created."
        )
        return self._prompt_confirm(msg, yes="Replace", no="Skip")

    @work(exclusive=True, thread=True)
    async def _run(self) -> None:
        orch = InstallerOrchestrator()

        log_fn, log_file = orch.create_log_sink(
            prefix=("update" if self._progress_task.kind == "update" else "install"),
            ui_log=self._ui_log,
        )

        try:
            if self._progress_task.kind == "update":
                self._set_step("Updating repository...", percent=5)
                await orch.update_repo(
                    log=log_fn, log_file=log_file, set_step=self._set_step
                )
                self._set_step("Done.", percent=100)
            else:
                assert self._progress_task.config is not None
                self._set_step("Starting...", percent=1)
                await orch.run_install(
                    self._progress_task.config,
                    log=log_fn,
                    log_file=log_file,
                    set_step=self._set_step,
                    prompt_replace=self._prompt_replace,
                    prompt_confirm=self._prompt_confirm,
                    prompt_password=self._prompt_password,
                )
                self._set_step("Done.", percent=100)
        except Exception as e:
            log_fn(f"[ERROR] {e}")
            self._set_step("Failed.")
        finally:
            self._show_back_button()

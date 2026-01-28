from __future__ import annotations

import asyncio
from typing import Literal, cast

from textual.app import App
from textual.binding import Binding

from dots_tui.logic.env_probe import ProbeResult, probe_environment
from dots_tui.logic.models import RunMode
from dots_tui.screens.config import ConfigScreen
from dots_tui.screens.menu import MenuScreen
from dots_tui.screens.progress import ProgressScreen

StartMode = RunMode | Literal["update"]


class InstallerApp(App[None]):
    TITLE = "Hyprland-Dots Installer"
    CSS_PATH = "installer.tcss"

    def __init__(
        self,
        *,
        dry_run: bool = False,
        start: StartMode | None = None,
        verbose: bool = False,
    ) -> None:
        super().__init__()
        self._dry_run = dry_run
        self._start = start
        self._verbose = verbose
        self._probe_task: asyncio.Task[ProbeResult] | None = None
        self._probe_lock = asyncio.Lock()

    BINDINGS = [
        Binding("ctrl+c", "app.quit", "Quit"),
    ]

    def on_mount(self) -> None:
        # Log startup info if verbose mode is enabled
        if self._verbose:
            self.log.info("Starting Hyprland-Dots Installer")
            self.log.info(f"  dry_run: {self._dry_run}")
            self.log.info(f"  start: {self._start}")
            self.log.info(f"  verbose: {self._verbose}")

        # Start probe immediately at mount to parallelize environment detection.
        self._probe_task = asyncio.create_task(probe_environment())
        if self._start == "update":
            self.push_screen(ProgressScreen.for_repo_update())
            return
        if self._start in {"install", "upgrade", "express"}:
            self.push_screen(
                ConfigScreen(
                    run_mode=cast(RunMode, self._start),
                    dry_run=self._dry_run,
                )
            )
            return

        self.push_screen(MenuScreen(dry_run=self._dry_run))

    async def get_probe(self) -> ProbeResult:
        """Get the environment probe result, creating the task if needed.

        Uses a lock to ensure probe_environment() is only called once even if
        multiple callers invoke get_probe() concurrently before the task is set.
        """
        async with self._probe_lock:
            if self._probe_task is None:
                self._probe_task = asyncio.create_task(probe_environment())
        return await self._probe_task


def run(
    *, dry_run: bool = False, start: StartMode | None = None, verbose: bool = False
) -> None:
    InstallerApp(dry_run=dry_run, start=start, verbose=verbose).run()

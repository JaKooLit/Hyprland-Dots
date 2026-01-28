from __future__ import annotations

import asyncio
import pytest

from dots_tui.logic.models import InstallConfig
from dots_tui.logic.orchestrator import InstallerOrchestrator

from tests.helpers import CmdRecorder, write_text


def test_dry_run_mode_makes_no_changes_but_emits_plan(
    fake_home,
    monkeypatch: pytest.MonkeyPatch,
    prompt_replace_yes,
    prompt_confirm_yes,
) -> None:
    repo_root = fake_home.home / "repo"
    (repo_root / "config").mkdir(parents=True)
    (repo_root / "scripts").mkdir(parents=True)

    write_text(
        repo_root / "config" / "hypr" / "configs" / "SystemSettings.conf",
        "  kb_layout = us\n",
    )
    (repo_root / "config" / "rofi" / "themes").mkdir(parents=True)
    (repo_root / "config" / "waybar" / "configs").mkdir(parents=True)
    write_text(repo_root / "config" / "waybar" / "configs" / "[TOP] Default", "{}\n")
    (repo_root / "config" / "waybar" / "style").mkdir(parents=True)
    write_text(
        repo_root / "config" / "waybar" / "style" / "[Extra] Neon Circuit.css",
        "/* css */\n",
    )

    recorder = CmdRecorder()
    monkeypatch.setattr("dots_tui.utils.run_cmd", recorder.run)
    monkeypatch.setattr("dots_tui.utils.is_root", lambda: False)
    monkeypatch.setattr("dots_tui.utils.which", lambda _cmd: None)
    monkeypatch.setattr(
        "dots_tui.logic.system.detect_distro", lambda: ("arch", [])
    )
    monkeypatch.setattr(
        "dots_tui.logic.system.detect_chassis", lambda: "desktop"
    )
    monkeypatch.setattr("dots_tui.logic.system.detect_nvidia", lambda: False)
    monkeypatch.setattr("dots_tui.logic.system.detect_vm", lambda: False)
    monkeypatch.setattr("dots_tui.logic.system.detect_nixos", lambda: False)
    monkeypatch.setattr(
        "dots_tui.logic.system.get_installed_dotfiles_version",
        lambda _root: None,
    )

    orch = InstallerOrchestrator()
    orch.repo_root = repo_root
    monkeypatch.setattr(orch, "_copy_logs_dir", lambda: fake_home.copy_logs)

    logs: list[str] = []

    def log(line: str) -> None:
        logs.append(line)

    cfg = InstallConfig(
        run_mode="install",
        resolution="gte_1440p",
        keyboard_layout="us",
        clock_24h=True,
        default_editor=None,
        download_wallpapers=False,
        apply_sddm_wallpaper=False,
        dry_run=True,
        enable_asus=False,
        enable_blueman=True,
        enable_ags=False,
        enable_quickshell=True,
    )

    # Act
    asyncio.run(
        orch.run_install(
            cfg,
            log=log,
            log_file=fake_home.copy_logs / "dry-run.log",
            set_step=lambda _m, _p: None,
            prompt_replace=prompt_replace_yes,
            prompt_confirm=prompt_confirm_yes,
        )
    )

    # Assert: no config output directories created (dry-run = no writes)
    assert not (fake_home.config / "hypr").exists()
    assert not (fake_home.config / "waybar").exists()
    assert not (fake_home.config / "rofi").exists()

    # Assert: plan lines exist
    assert any(line.startswith("[PLAN]") for line in logs)

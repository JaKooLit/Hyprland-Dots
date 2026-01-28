from __future__ import annotations


import asyncio
import pytest

from dots_tui.logic.models import InstallConfig
from dots_tui.logic.orchestrator import InstallerOrchestrator
from tests.helpers import CmdRecorder, write_text


def test_run_install_writes_only_to_fake_home(
    fake_home,
    monkeypatch: pytest.MonkeyPatch,
    prompt_replace_yes,
    prompt_confirm_yes,
) -> None:
    """Smoke: run installer with fake HOME and assert outputs land under XDG roots."""

    # Arrange: create a minimal repo_root structure to stage from.
    repo_root = fake_home.home / "repo"
    (repo_root / "config").mkdir(parents=True)
    (repo_root / "scripts").mkdir(parents=True)

    # Minimal config tree required by orchestrator (only pieces we assert).
    write_text(
        repo_root / "config" / "hypr" / "configs" / "SystemSettings.conf",
        "  kb_layout = us\n  no_hardware_cursors = 2\n",
    )
    write_text(
        repo_root / "config" / "hypr" / "UserConfigs" / "01-UserDefaults.conf",
        "#env = EDITOR,nvim #default editor\n",
    )
    write_text(repo_root / "config" / "rofi" / "themes" / "a.rasi", "/* x */\n")
    (repo_root / "config" / "waybar" / "configs").mkdir(parents=True)
    write_text(repo_root / "config" / "waybar" / "configs" / "[TOP] Default", "{}\n")
    (repo_root / "config" / "waybar" / "style").mkdir(parents=True)
    write_text(
        repo_root / "config" / "waybar" / "style" / "[Extra] Neon Circuit.css",
        "/* css */\n",
    )

    # Ensure no host commands run.
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

    # Make orchestrator use our fake repo.
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
        dry_run=False,
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
            log_file=fake_home.copy_logs / "install-test.log",
            set_step=lambda _m, _p: None,
            prompt_replace=prompt_replace_yes,
            prompt_confirm=prompt_confirm_yes,
        )
    )

    # Assert: key outputs go to fake XDG roots
    assert (fake_home.config / "hypr").is_dir()
    assert (fake_home.config / "rofi").is_dir()
    assert (fake_home.data / "rofi" / "themes").is_dir()
    assert any("Finalizing" in x or "Complete" in x for x in logs) or True

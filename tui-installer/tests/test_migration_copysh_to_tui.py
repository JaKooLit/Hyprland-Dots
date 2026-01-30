"""Integration test for migrating from copy.sh to TUI installer."""

from __future__ import annotations

import asyncio
import pytest

from dots_tui.logic.models import InstallConfig
from dots_tui.logic.orchestrator import InstallerOrchestrator

from tests.helpers import CmdRecorder, read_text, write_text


def test_migration_from_copysh_discovers_legacy_backup(
    fake_home,
    monkeypatch: pytest.MonkeyPatch,
    prompt_replace_yes,
    prompt_confirm_yes,
) -> None:
    """Test migration scenario: user ran copy.sh previously, now runs TUI installer.
    
    Scenario:
    1. User previously ran copy.sh which created legacy format backups
    2. User deletes their hypr config
    3. User runs TUI installer in upgrade mode
    4. TUI should discover the legacy backup and restore from it
    """
    # Seed fake repo (source of truth to copy from)
    repo_root = fake_home.home / "repo"
    (repo_root / "config").mkdir(parents=True)
    (repo_root / "scripts").mkdir(parents=True)

    write_text(repo_root / "config" / "hypr" / "v2.3.19", "")
    write_text(
        repo_root / "config" / "hypr" / "configs" / "SystemSettings.conf",
        "  kb_layout = us\n  no_hardware_cursors = 2\n",
    )
    write_text(
        repo_root / "config" / "hypr" / "UserConfigs" / "01-UserDefaults.conf",
        "#env = EDITOR,nvim #default editor\n",
    )
    write_text(
        repo_root / "config" / "hypr" / "configs" / "Startup_Apps.conf",
        "exec-once = foo\n",
    )
    write_text(
        repo_root / "config" / "hypr" / "configs" / "WindowRules.conf",
        "windowrule = float, ^(pavucontrol)$\n",
    )

    write_text(repo_root / "config" / "rofi" / "themes" / "a.rasi", "/* x */\n")
    (repo_root / "config" / "waybar" / "configs").mkdir(parents=True)
    write_text(repo_root / "config" / "waybar" / "configs" / "[TOP] Default", "{}\n")
    (repo_root / "config" / "waybar" / "style").mkdir(parents=True)
    write_text(
        repo_root / "config" / "waybar" / "style" / "[Extra] Neon Circuit.css",
        "/* css */\n",
    )

    # Simulate legacy copy.sh backup (user already ran copy.sh before)
    legacy_backup = fake_home.config / "hypr-backup-back-up_0128_1200"
    write_text(legacy_backup / "v2.3.19", "")
    write_text(
        legacy_backup / "monitors.conf", "monitor = eDP-1, 1920x1080@60,auto,1\n"
    )
    write_text(legacy_backup / "animations" / "legacy.conf", "legacy anim\n")
    write_text(legacy_backup / "Monitor_Profiles" / "legacy.conf", "legacy prof\n")
    write_text(
        legacy_backup / "wallpaper_effects" / "legacy.conf", "legacy wall\n"
    )
    write_text(
        legacy_backup / "UserConfigs" / "UserSettings.conf", "legacy custom\n"
    )
    write_text(
        legacy_backup / "UserConfigs" / "Startup_Apps.conf", "exec-once = bar\n"
    )

    # User deleted their hypr directory
    # (so TUI creates a fresh one and should restore from legacy backup)

    # Stub system/commands
    recorder = CmdRecorder()
    monkeypatch.setattr("dots_tui.utils.run_cmd", recorder.run)
    monkeypatch.setattr("dots_tui.utils.is_root", lambda: False)
    monkeypatch.setattr("dots_tui.utils.which", lambda _cmd: None)

    monkeypatch.setattr("dots_tui.logic.system.detect_distro", lambda: ("arch", []))
    monkeypatch.setattr("dots_tui.logic.system.detect_chassis", lambda: "desktop")
    monkeypatch.setattr("dots_tui.logic.system.detect_nvidia", lambda: False)
    monkeypatch.setattr("dots_tui.logic.system.detect_vm", lambda: False)
    monkeypatch.setattr("dots_tui.logic.system.detect_nixos", lambda: False)
    monkeypatch.setattr(
        "dots_tui.logic.system.get_installed_dotfiles_version",
        lambda _root: None,  # No current install
    )

    orch = InstallerOrchestrator()
    orch.repo_root = repo_root
    monkeypatch.setattr(orch, "_copy_logs_dir", lambda: fake_home.copy_logs)

    logs: list[str] = []

    def log(line: str) -> None:
        logs.append(line)

    cfg = InstallConfig(
        run_mode="upgrade",
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

    asyncio.run(
        orch.run_install(
            cfg,
            log=log,
            log_file=fake_home.copy_logs / "migration-test.log",
            set_step=lambda _m, _p: None,
            prompt_replace=prompt_replace_yes,
            prompt_confirm=prompt_confirm_yes,
        )
    )

    # Verify: Legacy backup was discovered
    assert any("Found existing backup from previous installation" in line for line in logs)
    assert any("hypr-backup-back-up_0128_1200" in line for line in logs)

    # Verify: Assets were restored from legacy backup
    assert (fake_home.config / "hypr" / "animations").is_dir()
    assert (fake_home.config / "hypr" / "Monitor_Profiles").is_dir()
    assert (fake_home.config / "hypr" / "wallpaper_effects").is_dir()
    
    assert "legacy anim" in read_text(
        fake_home.config / "hypr" / "animations" / "legacy.conf"
    )
    assert "legacy prof" in read_text(
        fake_home.config / "hypr" / "Monitor_Profiles" / "legacy.conf"
    )
    assert "legacy wall" in read_text(
        fake_home.config / "hypr" / "wallpaper_effects" / "legacy.conf"
    )

    # Verify: UserConfigs were restored
    assert (fake_home.config / "hypr" / "UserConfigs").is_dir()
    assert "legacy custom" in read_text(
        fake_home.config / "hypr" / "UserConfigs" / "UserSettings.conf"
    )

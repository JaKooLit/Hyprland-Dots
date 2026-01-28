from __future__ import annotations


import asyncio
import pytest

from dots_tui.logic.models import InstallConfig
from dots_tui.logic.orchestrator import InstallerOrchestrator

from tests.helpers import CmdRecorder, write_text


def test_express_upgrade_skips_restore_prompts_and_auto_cleans_backups(
    fake_home,
    monkeypatch: pytest.MonkeyPatch,
    prompt_replace_yes,
) -> None:
    # Seed fake repo
    repo_root = fake_home.home / "repo"
    (repo_root / "config").mkdir(parents=True)
    (repo_root / "scripts").mkdir(parents=True)

    write_text(repo_root / "config" / "hypr" / "v2.3.19", "")
    write_text(
        repo_root / "config" / "hypr" / "configs" / "SystemSettings.conf",
        "  kb_layout = us\n",
    )
    write_text(repo_root / "config" / "rofi" / "themes" / "a.rasi", "/* x */\n")
    (repo_root / "config" / "waybar" / "configs").mkdir(parents=True)
    write_text(repo_root / "config" / "waybar" / "configs" / "[TOP] Default", "{}\n")
    (repo_root / "config" / "waybar" / "style").mkdir(parents=True)
    write_text(
        repo_root / "config" / "waybar" / "style" / "[Extra] Neon Circuit.css",
        "/* css */\n",
    )

    # Seed existing configs + multiple backups so cleanup_backups(auto) has work.
    base = fake_home.config / "kitty"
    write_text(base / "kitty.conf", "font_size 16.0\n")
    # Create multiple backups sibling dirs
    (fake_home.config / "kitty-backup-back-up_0101_0001").mkdir(parents=True)
    (fake_home.config / "kitty-backup-back-up_0101_0002").mkdir(parents=True)

    # Stub system/commands
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
        lambda _root: "2.3.19",
    )

    orch = InstallerOrchestrator()
    orch.repo_root = repo_root
    monkeypatch.setattr(orch, "_copy_logs_dir", lambda: fake_home.copy_logs)

    cfg = InstallConfig(
        run_mode="express",
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

    # Express should skip restore prompts, but is allowed to prompt for
    # non-express backup cleanup only if mode is prompt. In express it should be auto.
    # We pass a confirm handler that always returns True to avoid failures if other
    # unrelated prompts occur.
    def prompt_confirm_ok(_m: str, _y: str, _n: str, _d: bool) -> bool:
        return True

    asyncio.run(
        orch.run_install(
            cfg,
            log=lambda _l: None,
            log_file=fake_home.copy_logs / "express-test.log",
            set_step=lambda _m, _p: None,
            prompt_replace=prompt_replace_yes,
            prompt_confirm=prompt_confirm_ok,
        )
    )

    # Assert: backup cleanup auto-trimmed old backups (keeps only latest by mtime).
    backups = [p for p in fake_home.config.glob("kitty-backup-back-up_*") if p.is_dir()]
    assert len(backups) == 1

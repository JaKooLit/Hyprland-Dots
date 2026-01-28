from __future__ import annotations


import asyncio
import pytest

from dots_tui.logic.models import InstallConfig
from dots_tui.logic.orchestrator import InstallerOrchestrator

from tests.helpers import CmdRecorder, read_text, write_text


def test_waybar_symlink_targets_copied_into_real_files(
    fake_home,
    monkeypatch: pytest.MonkeyPatch,
    prompt_replace_yes,
    prompt_confirm_yes,
) -> None:
    repo_root = fake_home.home / "repo"
    (repo_root / "config").mkdir(parents=True)
    (repo_root / "scripts").mkdir(parents=True)

    # Minimal required repo config for waybar.
    (repo_root / "config" / "hypr" / "configs").mkdir(parents=True)
    write_text(
        repo_root / "config" / "hypr" / "configs" / "SystemSettings.conf", "kb\n"
    )
    (repo_root / "config" / "waybar" / "configs").mkdir(parents=True)
    write_text(repo_root / "config" / "waybar" / "configs" / "[TOP] Default", "{}\n")
    (repo_root / "config" / "waybar" / "style").mkdir(parents=True)
    write_text(
        repo_root / "config" / "waybar" / "style" / "[Extra] Neon Circuit.css",
        "/* css new */\n",
    )

    # Existing waybar with config/style.css as symlinks to external targets.
    waybar = fake_home.config / "waybar"
    (waybar / "configs").mkdir(parents=True)
    (waybar / "style").mkdir(parents=True)
    external = fake_home.home / "external"
    external.mkdir(parents=True)
    ext_cfg = external / "cfg.json"
    ext_css = external / "theme.css"
    write_text(ext_cfg, '{"old": true}\n')
    write_text(ext_css, "/* old css */\n")
    (waybar / "config").symlink_to(ext_cfg)
    (waybar / "style.css").symlink_to(ext_css)
    write_text(waybar / "UserModules", "mods\n")

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

    cfg = InstallConfig(
        run_mode="install",
        resolution="gte_1440p",
        keyboard_layout="us",
        clock_24h=True,
        default_editor=None,
        download_wallpapers=False,
        apply_sddm_wallpaper=True,
        dry_run=False,
        enable_asus=False,
        enable_blueman=True,
        enable_ags=False,
        enable_quickshell=True,
    )

    asyncio.run(
        orch.run_install(
            cfg,
            log=lambda message: None,
            log_file=fake_home.copy_logs / "waybar-symlink-test.log",
            set_step=lambda _m, _p: None,
            prompt_replace=prompt_replace_yes,
            prompt_confirm=prompt_confirm_yes,
        )
    )

    # Verify shell parity: config/style.css should be real files with original target contents.
    assert (waybar / "config").is_file() and not (waybar / "config").is_symlink()
    assert (waybar / "style.css").is_file() and not (waybar / "style.css").is_symlink()
    assert '"old"' in read_text(waybar / "config")
    assert "old css" in read_text(waybar / "style.css")

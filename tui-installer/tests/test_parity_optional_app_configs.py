from __future__ import annotations

import asyncio
import pytest

from dots_tui.logic.models import InstallConfig
from dots_tui.logic.orchestrator import InstallerOrchestrator

from tests.helpers import CmdRecorder, read_text, write_text


def test_quickshell_skip_overwrite_removes_shell_qml_and_installs_overview(
    fake_home,
    monkeypatch: pytest.MonkeyPatch,
    prompt_replace_yes,
    prompt_confirm_no,
) -> None:
    repo_root = fake_home.home / "repo"
    (repo_root / "config").mkdir(parents=True)
    (repo_root / "scripts").mkdir(parents=True)

    # Minimal required configs.
    write_text(
        repo_root / "config" / "hypr" / "configs" / "SystemSettings.conf",
        "  kb_layout = us\n",
    )
    write_text(
        repo_root / "config" / "hypr" / "configs" / "Startup_Apps.conf",
        "exec-once = qs &\n",
    )
    (repo_root / "config" / "rofi" / "themes").mkdir(parents=True)
    (repo_root / "config" / "waybar" / "configs").mkdir(parents=True)
    write_text(repo_root / "config" / "waybar" / "configs" / "[TOP] Default", "{}\n")
    (repo_root / "config" / "waybar" / "style").mkdir(parents=True)
    write_text(
        repo_root / "config" / "waybar" / "style" / "[Extra] Neon Circuit.css",
        "/* css */\n",
    )

    # Source quickshell config in repo (overview exists).
    write_text(repo_root / "config" / "quickshell" / "shell.qml", "// new\n")
    write_text(repo_root / "config" / "quickshell" / "overview" / "a.qml", "// o\n")

    # Existing quickshell install triggers overwrite prompt.
    write_text(fake_home.config / "quickshell" / "shell.qml", "// old\n")

    recorder = CmdRecorder()
    monkeypatch.setattr("dots_tui.utils.run_cmd", recorder.run)
    monkeypatch.setattr("dots_tui.utils.is_root", lambda: False)

    def which(cmd: str) -> str | None:
        if cmd in {"qs"}:
            return f"/usr/bin/{cmd}"
        return None

    monkeypatch.setattr("dots_tui.utils.which", which)
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
        run_mode="install",
        resolution="gte_1440p",
        keyboard_layout="us",
        clock_24h=True,
        default_editor=None,
        download_wallpapers=False,
        apply_sddm_wallpaper=False,
        dry_run=False,
        enable_asus=False,
        enable_blueman=False,
        enable_ags=False,
        enable_quickshell=True,
    )

    asyncio.run(
        orch.run_install(
            cfg,
            log=lambda _l: None,
            log_file=fake_home.copy_logs / "optional-apps.log",
            set_step=lambda _m, _p: None,
            prompt_replace=prompt_replace_yes,
            prompt_confirm=prompt_confirm_no,
        )
    )

    # Even when we skip overwrite, shell.qml is removed and overview is ensured.
    assert not (fake_home.config / "quickshell" / "shell.qml").exists()
    assert (fake_home.config / "quickshell" / "overview").is_dir()


def test_quickshell_overwrite_rewrites_startup_and_removes_new_shell_qml(
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
    write_text(
        repo_root / "config" / "hypr" / "configs" / "Startup_Apps.conf",
        "exec-once = qs\n",
    )
    (repo_root / "config" / "rofi" / "themes").mkdir(parents=True)
    (repo_root / "config" / "waybar" / "configs").mkdir(parents=True)
    write_text(repo_root / "config" / "waybar" / "configs" / "[TOP] Default", "{}\n")
    (repo_root / "config" / "waybar" / "style").mkdir(parents=True)
    write_text(
        repo_root / "config" / "waybar" / "style" / "[Extra] Neon Circuit.css",
        "/* css */\n",
    )

    # Source quickshell config in repo.
    write_text(repo_root / "config" / "quickshell" / "shell.qml", "// new\n")
    write_text(repo_root / "config" / "quickshell" / "overview" / "a.qml", "// o\n")

    # Existing quickshell install triggers overwrite prompt.
    write_text(fake_home.config / "quickshell" / "shell.qml", "// old\n")
    write_text(fake_home.config / "quickshell" / "keep.txt", "keep\n")

    recorder = CmdRecorder()
    monkeypatch.setattr("dots_tui.utils.run_cmd", recorder.run)
    monkeypatch.setattr("dots_tui.utils.is_root", lambda: False)

    def which(cmd: str) -> str | None:
        if cmd in {"qs"}:
            return f"/usr/bin/{cmd}"
        return None

    monkeypatch.setattr("dots_tui.utils.which", which)
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
        run_mode="install",
        resolution="gte_1440p",
        keyboard_layout="us",
        clock_24h=True,
        default_editor=None,
        download_wallpapers=False,
        apply_sddm_wallpaper=False,
        dry_run=False,
        enable_asus=False,
        enable_blueman=False,
        enable_ags=False,
        enable_quickshell=True,
    )

    asyncio.run(
        orch.run_install(
            cfg,
            log=lambda _l: None,
            log_file=fake_home.copy_logs / "optional-apps.log",
            set_step=lambda _m, _p: None,
            prompt_replace=prompt_replace_yes,
            prompt_confirm=prompt_confirm_yes,
        )
    )

    # New config installed, but shell.qml is removed after copy.
    assert (fake_home.config / "quickshell").is_dir()
    assert not (fake_home.config / "quickshell" / "shell.qml").exists()
    assert (fake_home.config / "quickshell" / "overview" / "a.qml").is_file()

    # Startup apps rewritten.
    txt = read_text(fake_home.config / "hypr" / "configs" / "Startup_Apps.conf")
    assert "exec-once = qs -c overview" in txt

from __future__ import annotations

import os
import re
import shutil
from pathlib import Path

from dots_tui.logic.system import version_gte
from dots_tui.logic.dedupe import cleanup_duplicate_userconfigs
from dots_tui.logic.path_safety import assert_safe_path
from dots_tui.logic.models import LogFn, PromptConfirmFn

# Backward compatibility alias
PromptConfirm = PromptConfirmFn


TARGET_USERCONFIGS_VERSION = "2.3.19"


def _ensure_parent(dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)


def _copy_symlink(src: Path, dst: Path) -> None:
    assert_safe_path(dst)
    target = os.readlink(src)
    if dst.exists() or dst.is_symlink():
        if dst.is_dir() and not dst.is_symlink():
            shutil.rmtree(dst)
        else:
            dst.unlink(missing_ok=True)
    _ensure_parent(dst)
    dst.symlink_to(target)


def _copy_file(src: Path, dst: Path) -> None:
    assert_safe_path(dst)
    _ensure_parent(dst)
    if dst.exists() or dst.is_symlink():
        try:
            if dst.is_dir() and not dst.is_symlink():
                shutil.rmtree(dst)
            else:
                dst.unlink(missing_ok=True)
        except Exception:
            pass
    shutil.copy2(src, dst)


def merge_tree(src: Path, dst: Path) -> None:
    """Merge-copy src into dst (rsync -a style, without delete)."""

    dst.mkdir(parents=True, exist_ok=True)
    for child in src.iterdir():
        out = dst / child.name
        if child.is_symlink():
            _copy_symlink(child, out)
        elif child.is_dir():
            merge_tree(child, out)
        else:
            _copy_file(child, out)


def _find_current_hypr_version(hypr_dir: Path) -> str:
    for p in sorted(hypr_dir.iterdir(), key=lambda x: x.name):
        if p.is_file() and re.fullmatch(r"v\d+\.\d+\.\d+", p.name):
            return p.name[1:]
    # Match lib_copy.sh default: treat as newer.
    return "999.9.9"


def restore_hypr_assets(
    *, backup_hypr_dir: Path, hypr_dir: Path, express: bool, log: LogFn
) -> None:
    if express:
        log(
            "[NOTE] Express mode: skipping automatic restoration of animations and monitor profiles."
        )
        return

    if not backup_hypr_dir.is_dir():
        return

    for name in ["Monitor_Profiles", "animations", "wallpaper_effects"]:
        src = backup_hypr_dir / name
        if src.is_dir():
            try:
                merge_tree(src, hypr_dir / name)
                log(f"[OK] - Restored directory: {name}")
            except Exception:
                pass

    for name in ["monitors.conf", "workspaces.conf"]:
        src = backup_hypr_dir / name
        if src.is_file():
            try:
                _copy_file(src, hypr_dir / name)
                log(f"[OK] - Restored file: {name}")
            except Exception:
                pass


def _prompt(
    prompt_confirm: PromptConfirm | None,
    *,
    message: str,
    yes: str,
    no: str,
    default_yes: bool,
    log: LogFn,
) -> bool:
    if prompt_confirm is None:
        log("[WARN] No prompt handler; using default choice")
        return default_yes
    return prompt_confirm(message, yes, no, default_yes)


def restore_user_configs(
    *,
    backup_hypr_dir: Path,
    hypr_dir: Path,
    express: bool,
    prompt_confirm: PromptConfirm | None,
    log: LogFn,
    old_version: str | None = None,
) -> None:
    backup_userconfigs = backup_hypr_dir / "UserConfigs"
    if not backup_userconfigs.is_dir():
        return

    if express:
        log("[NOTE] Express mode: skipping UserConfigs restoration prompts.")
        # Even in express mode, we run cleanup at the end.
    else:
        current_version = _find_current_hypr_version(hypr_dir)
        if old_version:
            current_version = old_version

        log("[NOTE] Restoring previous User-Configs...")
        if version_gte(current_version, TARGET_USERCONFIGS_VERSION):
            msg = (
                "Restore your previous UserConfigs directory?\n\n"
                "This directory contains personal overrides that will supersede defaults."
            )
            if _prompt(
                prompt_confirm,
                message=msg,
                yes="Restore",
                no="Skip",
                default_yes=True,
                log=log,
            ):
                try:
                    merge_tree(backup_userconfigs, hypr_dir / "UserConfigs")
                    log("[OK] - UserConfigs directory restored.")
                except Exception:
                    log("[ERROR] - Failed to restore UserConfigs directory.")
            else:
                log("[NOTE] - Skipped restoring UserConfigs.")
        else:
            # Legacy restoration mode.
            log(
                f"[NOTE] Detected version v{current_version} (older than v{TARGET_USERCONFIGS_VERSION}). Using legacy restoration mode."
            )

            files_to_restore = [
                "01-UserDefaults.conf",
                "ENVariables.conf",
                "LaptopDisplay.conf",
                "Laptops.conf",
                "Startup_Apps.conf",
                "UserDecorations.conf",
                "UserAnimations.conf",
                "UserKeybinds.conf",
                "UserSettings.conf",
                "WindowRules.conf",
            ]

            for name in files_to_restore:
                src = backup_userconfigs / name
                if not src.is_file():
                    continue

                if name == "Startup_Apps.conf":
                    _compose_overlay_from_backup(
                        overlay_type="startup",
                        base_file=hypr_dir / "configs" / "Startup_Apps.conf",
                        old_user_file=src,
                        new_user_file=hypr_dir / "UserConfigs" / "Startup_Apps.conf",
                        disable_file=hypr_dir / "UserConfigs" / "Startup_Apps.disable",
                    )
                    log(f"[OK] - Migrated overlay for {name}")
                    continue

                if name == "WindowRules.conf":
                    _compose_overlay_from_backup(
                        overlay_type="windowrules",
                        base_file=hypr_dir / "configs" / "WindowRules.conf",
                        old_user_file=src,
                        new_user_file=hypr_dir / "UserConfigs" / "WindowRules.conf",
                        disable_file=hypr_dir / "UserConfigs" / "WindowRules.disable",
                    )
                    log(f"[OK] - Migrated overlay for {name}")
                    continue

                msg = f"Found {name} in hypr backup.\n\nRestore it from backup?"
                if _prompt(
                    prompt_confirm,
                    message=msg,
                    yes="Restore",
                    no="Skip",
                    default_yes=True,
                    log=log,
                ):
                    try:
                        _copy_file(src, hypr_dir / "UserConfigs" / name)
                        log(f"[OK] - {name} restored!")
                    except Exception:
                        log(f"[ERROR] - Failed to restore {name}!")
                else:
                    log(f"[NOTE] - Skipped restoring {name}.")

    # Always run de-dupe logic.
    detected_version = old_version
    if not detected_version:
        detected_version = _find_current_hypr_version(hypr_dir)
    cleanup_duplicate_userconfigs(detected_version, log, hypr_dir)


def restore_user_scripts(
    *,
    backup_hypr_dir: Path,
    hypr_dir: Path,
    express: bool,
    prompt_confirm: PromptConfirm | None,
    log: LogFn,
) -> None:
    backup_userscripts = backup_hypr_dir / "UserScripts"
    if not backup_userscripts.is_dir():
        return

    if express:
        log("[NOTE] Express mode: skipping UserScripts restoration prompts.")
        return

    scripts = ["RofiBeats.sh", "Weather.py", "Weather.sh"]
    dst_dir = hypr_dir / "UserScripts"
    dst_dir.mkdir(parents=True, exist_ok=True)

    log("[NOTE] Restoring previous User-Scripts...")
    for name in scripts:
        src = backup_userscripts / name
        if not src.is_file():
            continue
        msg = f"Found {name} in hypr backup.\n\nRestore it from backup?"
        if _prompt(
            prompt_confirm,
            message=msg,
            yes="Restore",
            no="Skip",
            default_yes=False,
            log=log,
        ):
            try:
                _copy_file(src, dst_dir / name)
                log(f"[OK] - {name} restored!")
            except Exception:
                log(f"[ERROR] - Failed to restore {name}!")
        else:
            log(f"[NOTE] - Skipped restoring {name}.")


def restore_hypr_files(
    *,
    backup_hypr_dir: Path,
    hypr_dir: Path,
    express: bool,
    prompt_confirm: PromptConfirm | None,
    log: LogFn,
) -> None:
    if express:
        log("[NOTE] Express mode: skipping individual hypr file restoration prompts.")
        return

    files = ["hyprlock.conf", "hypridle.conf"]
    for name in files:
        src = backup_hypr_dir / name
        if not src.is_file():
            continue
        msg = f"Found {name} in hypr backup.\n\nRestore it from backup?"
        if _prompt(
            prompt_confirm,
            message=msg,
            yes="Restore",
            no="Skip",
            default_yes=False,
            log=log,
        ):
            try:
                _copy_file(src, hypr_dir / name)
                log(f"[OK] - {name} restored!")
            except Exception:
                log(f"[ERROR] - Failed to restore {name}!")
        else:
            log(f"[NOTE] - Skipped restoring {name}.")


def _compose_overlay_from_backup(
    *,
    overlay_type: str,  # startup|windowrules
    base_file: Path,
    old_user_file: Path,
    new_user_file: Path,
    disable_file: Path,
) -> None:
    new_user_file.parent.mkdir(parents=True, exist_ok=True)
    new_user_file.write_text("", encoding="utf-8")
    disable_file.write_text("", encoding="utf-8")

    base_txt = (
        base_file.read_text(encoding="utf-8", errors="replace")
        if base_file.is_file()
        else ""
    )
    old_txt = old_user_file.read_text(encoding="utf-8", errors="replace")

    if overlay_type == "startup":
        old_exec = _extract_exec_once(old_txt, commented=False)
        base_exec = _extract_exec_once(base_txt, commented=False)
        overlay_lines = sorted(set(old_exec) - set(base_exec))
        new_user_file.write_text(
            "".join(f"{line}\n" for line in overlay_lines),
            encoding="utf-8",
        )

        disabled_cmds = _extract_exec_once_disabled_commands(old_txt)
        disabled_cmds = [
            c for c in disabled_cmds if c != "$scriptsDir/KeybindsLayoutInit.sh"
        ]
        disable_file.write_text(
            "".join(f"{c}\n" for c in sorted(set(disabled_cmds))), encoding="utf-8"
        )
        return

    if overlay_type == "windowrules":
        old_rules = _extract_rules(old_txt, commented=False)
        base_rules = _extract_rules(base_txt, commented=False)
        overlay_lines = sorted(set(old_rules) - set(base_rules))
        new_user_file.write_text(
            "".join(f"{line}\n" for line in overlay_lines),
            encoding="utf-8",
        )

        disabled_rules = _extract_rules(old_txt, commented=True)
        disable_file.write_text(
            "".join(f"{line}\n" for line in sorted(set(disabled_rules))),
            encoding="utf-8",
        )
        return


def _extract_exec_once(text: str, *, commented: bool) -> list[str]:
    out: list[str] = []
    for raw in text.splitlines():
        line = raw.strip()
        if not line:
            continue
        if commented:
            if not re.match(r"^#\s*exec-once\s*=", line):
                continue
            line = re.sub(r"^#\s*", "", line)
        else:
            if line.startswith("#"):
                continue
            if not re.match(r"^exec-once\s*=", line):
                continue
        out.append(line)
    return out


def _extract_exec_once_disabled_commands(text: str) -> list[str]:
    out: list[str] = []
    for raw in text.splitlines():
        line = raw.strip()
        if not line:
            continue
        m = re.match(r"^#\s*exec-once\s*=\s*(.+)$", line)
        if not m:
            continue
        out.append(m.group(1).strip())
    return out


def _extract_rules(text: str, *, commented: bool) -> list[str]:
    out: list[str] = []
    for raw in text.splitlines():
        line = raw.strip()
        if not line:
            continue
        if commented:
            if not re.match(r"^#\s*(windowrule|layerrule)\s*=", line):
                continue
            line = re.sub(r"^#\s*", "", line)
            out.append(line.strip())
            continue

        if line.startswith("#"):
            continue
        if re.match(r"^(windowrule|layerrule)\s*=", line):
            out.append(line)
    return out

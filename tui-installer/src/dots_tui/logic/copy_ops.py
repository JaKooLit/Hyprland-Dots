from __future__ import annotations

import os
import shutil
from pathlib import Path

from dots_tui.logic.backup import backup_dir, backup_dir_copy
from dots_tui.logic.path_safety import assert_safe_path


def _copytree(src: Path, dst: Path) -> None:
    """Copy a directory tree, replacing destination if it exists.

    Raises:
        RuntimeError: If permission is denied during removal or copy.
    """
    assert_safe_path(dst)
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.exists():
        try:
            shutil.rmtree(dst)
        except PermissionError as e:
            raise RuntimeError(
                f"Permission denied removing existing directory {dst}: {e}"
            ) from e
    try:
        shutil.copytree(src, dst, symlinks=True)
    except PermissionError as e:
        raise RuntimeError(f"Permission denied copying to {dst}: {e}") from e


def copy_config_dir(
    *,
    name: str,
    staging_config_root: Path,
    target_config_root: Path,
) -> Path | None:
    src = staging_config_root / name
    if not src.exists():
        return None

    dst = target_config_root / name
    backup: Path | None = None
    if dst.exists():
        backup = backup_dir(dst)
    _copytree(src, dst)
    return backup


def copy_phase1_dir(
    *,
    name: str,
    staging_config_root: Path,
    target_config_root: Path,
    log,
) -> Path | None:
    src = staging_config_root / name
    dst = target_config_root / name
    if not src.exists():
        return None

    backup: Path | None = None
    if dst.exists():
        backup = backup_dir(dst)
        log(f"[NOTE] - Backed up {name} to {backup}")

    _copytree(src, dst)
    log(f"[OK] - Installed {name}")
    return backup


def restore_rofi_from_backup(*, backup_dir: Path, rofi_dir: Path, log) -> None:
    themes_backup = backup_dir / "themes"
    themes_dst = rofi_dir / "themes"
    if themes_backup.is_dir() and themes_dst.is_dir():
        for p in themes_backup.iterdir():
            if not p.exists():
                continue
            dst = themes_dst / p.name
            if not dst.exists() and p.is_file():
                try:
                    shutil.copy2(p, dst)
                except OSError:
                    pass

    fonts_backup = backup_dir / "0-shared-fonts.rasi"
    if fonts_backup.is_file():
        try:
            shutil.copy2(fonts_backup, rofi_dir / "0-shared-fonts.rasi")
            log("[OK] - Restored rofi 0-shared-fonts.rasi from backup")
        except OSError:
            pass


def copy_waybar_with_merge(
    *,
    staging_config_root: Path,
    target_config_root: Path,
    log,
) -> None:
    name = "waybar"
    src = staging_config_root / name
    dst = target_config_root / name
    if not src.exists():
        return

    if not dst.exists():
        _copytree(src, dst)
        log("[OK] - Installed waybar")
        return

    backup = backup_dir_copy(dst)
    log(f"[NOTE] - Backed up waybar to {backup}")

    # Replace with new.
    shutil.rmtree(dst)
    shutil.copytree(src, dst, symlinks=True)

    assert backup is not None

    # If previous config/style.css were symlinks, copy their targets into new files.
    for rel in ["config", "style.css"]:
        old = backup / rel
        new = dst / rel
        if old.is_symlink():
            try:
                target = old.resolve(strict=True)
            except FileNotFoundError:
                continue
            if target.is_file():
                try:
                    if new.exists() or new.is_symlink():
                        new.unlink()
                    shutil.copy2(target, new)
                except OSError:
                    pass

    # Merge missing configs/
    old_configs = backup / "configs"
    new_configs = dst / "configs"
    if old_configs.is_dir() and new_configs.is_dir():
        for p in old_configs.iterdir():
            target = new_configs / p.name
            if target.exists():
                continue
            try:
                if p.is_dir():
                    shutil.copytree(p, target, symlinks=True)
                else:
                    shutil.copy2(p, target)
            except OSError:
                pass

    # Merge missing style/
    old_style = backup / "style"
    new_style = dst / "style"
    if old_style.is_dir() and new_style.is_dir():
        for p in old_style.iterdir():
            target = new_style / p.name
            if target.exists():
                continue
            try:
                if p.is_dir():
                    shutil.copytree(p, target, symlinks=True)
                else:
                    shutil.copy2(p, target)
            except OSError:
                pass

    # Restore UserModules
    um = backup / "UserModules"
    if um.is_file():
        try:
            shutil.copy2(um, dst / "UserModules")
        except OSError:
            pass

    log("[OK] - Installed waybar (merged from backup)")


def install_file(*, src: Path, dst: Path, mode: int = 0o644) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
    os.chmod(dst, mode)

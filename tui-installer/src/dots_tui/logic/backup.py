from __future__ import annotations

from datetime import datetime
from pathlib import Path
from typing import Literal

import shutil

from dots_tui.logic.path_safety import assert_safe_path
from dots_tui.logic.models import LogFn, PromptConfirmFn

# Backward compatibility alias
PromptConfirm = PromptConfirmFn


def backup_suffix() -> str:
    # Format: MMDD_HHMM (Clean timestamp)
    return datetime.now().strftime("%m%d_%H%M")


def backup_path(path: Path) -> Path:
    # Target: {name}-backup-{MMDD}_{HHMM}
    return path.with_name(f"{path.name}-backup-{backup_suffix()}")


def backup_dir(path: Path) -> Path | None:
    if not path.exists():
        return None
    dst = backup_path(path)
    path.rename(dst)
    return dst


def backup_dir_copy(path: Path) -> Path | None:
    """Backup directory via copy (shell waybar behavior).
    Used when we want to preserve symlinks and file metadata without moving the
    original directory out from under any running process.
    """

    if not path.exists():
        return None
    dst = backup_path(path)
    shutil.copytree(path, dst, symlinks=True)
    return dst


def cleanup_backups(
    *,
    mode: Literal["auto", "prompt"],
    log: LogFn,
    prompt_confirm: PromptConfirm | None = None,
    config_root: Path | None = None,
) -> None:
    """Trim old backups in ~/.config
    For each directory ~/.config/<name>, if multiple sibling directories named
    '<name>-backup*' exist, keep the newest by mtime and delete older ones.
    """

    root = config_root or (Path.home() / ".config")
    assert_safe_path(root)
    if not root.is_dir():
        return

    for base in root.iterdir():
        if not base.is_dir():
            continue

        pattern = f"{base.name}-backup*"
        backups = [p for p in root.glob(pattern) if p.is_dir()]
        if len(backups) <= 1:
            continue

        latest = max(backups, key=lambda p: p.stat().st_mtime)
        old = [p for p in backups if p != latest]
        if not old:
            continue

        if mode == "prompt":
            msg = (
                f"Found {len(backups)} backups for {base.name}.\n\n"
                "Delete older backups and keep only the latest?\n\n"
                f"Keeping: {latest.name}"
            )
            ok = False
            if prompt_confirm is not None:
                ok = prompt_confirm(msg, "Delete", "Keep", False)
            if not ok:
                log(f"[NOTE] - Keeping existing backups for {base.name}.")
                continue

        for b in sorted(old, key=lambda p: p.stat().st_mtime):
            try:
                shutil.rmtree(b)
                log(f"[NOTE] - Removed old backup: {b.name}")
            except Exception:
                log(f"[WARN] - Failed to remove backup: {b.name}")

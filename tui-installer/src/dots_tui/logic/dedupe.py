from __future__ import annotations

import re
import shutil
from datetime import datetime
from pathlib import Path

from dots_tui.logic.system import version_gte
from dots_tui.utils import LogFn


def _trim(s: str) -> str:
    return s.strip()


def _strip_duplicates_from_file(
    base_file: Path,
    user_file: Path,
    pattern: re.Pattern[str],
    log: LogFn,
    desc: str,
) -> None:
    if not (base_file.is_file() and user_file.is_file()):
        return
    base_lines = set()
    try:
        base_content = base_file.read_text(encoding="utf-8", errors="replace")
        for line in base_content.splitlines():
            if pattern.search(line):
                base_lines.add(_trim(line))
    except Exception:
        return

    # Process user file.
    new_lines = []
    changed = False
    try:
        user_content = user_file.read_text(encoding="utf-8", errors="replace")
        for line in user_content.splitlines():
            if pattern.search(line):
                trimmed = _trim(line)
                if trimmed in base_lines:
                    # Duplicate found; skip it.
                    changed = True
                    continue
            new_lines.append(line)
    except Exception:
        return

    if changed:
        ts = datetime.now().strftime("%Y%m%d-%H%M%S")
        backup = user_file.with_name(f"{user_file.name}.backup-dupfix-{ts}")
        try:
            shutil.copy2(user_file, backup)
            user_file.write_text("\n".join(new_lines) + "\n", encoding="utf-8")
            log(f"[NOTE] - Removed duplicate {desc} entries matching base config.")
        except Exception as e:
            log(f"[WARN] Failed to update {user_file.name}: {e}")


def cleanup_duplicate_userconfigs(
    current_version: str,
    log: LogFn,
    hypr_dir: Path | None = None,
) -> None:
    """Run de-dupe logic for UserConfigs against base configs."""
    if not current_version:
        return

    # Logic mirrors scripts/lib_copy.sh: skip if version >= 2.3.20.
    if version_gte(current_version, "2.3.20"):
        log(
            f"[INFO] Skipping UserConfigs duplicate cleanup for detected version v{current_version} (>= 2.3.20)."
        )
        return

    log(
        f"[INFO] Running UserConfigs duplicate cleanup for detected version v{current_version} (<= 2.3.19)."
    )

    if hypr_dir is None:
        hypr_dir = Path.home() / ".config/hypr"

    base_dir = hypr_dir / "configs"
    user_dir = hypr_dir / "UserConfigs"

    # 1. Startup_Apps
    _strip_duplicates_from_file(
        base_file=base_dir / "Startup_Apps.conf",
        user_file=user_dir / "Startup_Apps.conf",
        pattern=re.compile(r"^\s*exec-once\s*="),
        log=log,
        desc="Startup_Apps",
    )

    # 2. WindowRules
    _strip_duplicates_from_file(
        base_file=base_dir / "WindowRules.conf",
        user_file=user_dir / "WindowRules.conf",
        pattern=re.compile(r"^\s*(windowrule|layerrule)\s*="),
        log=log,
        desc="WindowRules",
    )

    # Pattern: bind, bindl, bindm, bindd, etc.
    _strip_duplicates_from_file(
        base_file=base_dir / "Keybinds.conf",
        user_file=user_dir / "UserKeybinds.conf",
        pattern=re.compile(r"^\s*bind[a-z]*\s*="),
        log=log,
        desc="UserKeybinds",
    )

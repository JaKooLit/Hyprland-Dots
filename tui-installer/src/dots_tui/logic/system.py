"""Synchronous system detection utilities for runtime use.

This module provides synchronous versions of system detection functions used
during the actual installation process (runtime).

NOTE: Some functions here intentionally duplicate logic from env_probe.py:
- env_probe.py contains async versions used during app startup (probing)
- system.py contains synchronous versions used during installation (runtime)

This separation allows the TUI to remain responsive during initial environment
detection while still having synchronous access to the same information during
the actual installation process.
"""

from __future__ import annotations

import os
import re
import subprocess
from pathlib import Path
from typing import Literal

from dots_tui.utils import which


MIN_EXPRESS_VERSION = "2.3.18"


def version_gte(a: str, b: str) -> bool:
    """Return True if a >= b for simple X.Y.Z versions."""

    def parse(v: str) -> tuple[int, int, int] | None:
        m = re.fullmatch(r"(\d+)\.(\d+)\.(\d+)", v.strip())
        if not m:
            return None
        return (int(m.group(1)), int(m.group(2)), int(m.group(3)))

    pa = parse(a)
    pb = parse(b)
    if pa is None or pb is None:
        return False
    return pa >= pb


def express_supported(config_root: Path | None = None) -> bool:
    v = get_installed_dotfiles_version(config_root)
    if not v:
        return False
    return version_gte(v, MIN_EXPRESS_VERSION)


def _run_capture(argv: list[str]) -> str:
    try:
        return subprocess.check_output(argv, stderr=subprocess.STDOUT, text=True)
    except Exception:
        return ""


def detect_keyboard_layout() -> str | None:
    if which("localectl"):
        out = _run_capture(["localectl", "status", "--no-pager"])
        m = re.search(r"^\s*X11\s+Layout:\s*(\S+)\s*$", out, re.MULTILINE)
        if m:
            return m.group(1)

    if which("setxkbmap"):
        out = _run_capture(["setxkbmap", "-query"])
        m = re.search(r"^\s*layout:\s*(\S+)\s*$", out, re.MULTILINE)
        if m:
            return m.group(1)

    return None


def detect_chassis() -> Literal["desktop", "laptop"]:
    out = _run_capture(["hostnamectl"]) if which("hostnamectl") else ""
    if "Chassis: desktop" in out:
        return "desktop"
    return "laptop"


def detect_nixos() -> bool:
    out = _run_capture(["hostnamectl"]) if which("hostnamectl") else ""
    return "Operating System: NixOS" in out


def detect_vm() -> bool:
    out = _run_capture(["hostnamectl"]) if which("hostnamectl") else ""
    return "Chassis: vm" in out


def detect_nvidia() -> bool:
    if not which("lspci"):
        return False
    out = _run_capture(["lspci", "-k"])
    return bool(re.search(r"\bnvidia\b", out, re.IGNORECASE))


def replace_kb_layout(system_settings_conf: Path, layout: str) -> None:
    text = system_settings_conf.read_text(
        encoding="utf-8", errors="replace"
    ).splitlines(True)
    out: list[str] = []
    replaced = False
    for line in text:
        if "kb_layout" in line and "=" in line and not line.lstrip().startswith("#"):
            indent = line.split("k", 1)[0]
            out.append(f"{indent}kb_layout = {layout}\n")
            replaced = True
        else:
            out.append(line)
    if not replaced:
        out.append(f"  kb_layout = {layout}\n")
    system_settings_conf.write_text("".join(out), encoding="utf-8")


def read_os_release(path: Path = Path("/etc/os-release")) -> dict[str, str]:
    """Parse /etc/os-release into a dict.

    This intentionally implements only what we need (ID, ID_LIKE) and tolerates
    missing files/keys.
    """

    if not path.is_file():
        return {}

    out: dict[str, str] = {}
    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        v = v.strip().strip('"')
        out[k] = v
    return out


def detect_distro() -> tuple[str | None, tuple[str, ...]]:
    data = read_os_release()
    distro_id = data.get("ID")
    id_like = data.get("ID_LIKE", "").strip()
    distro_like = tuple(s for s in re.split(r"\s+", id_like) if s)
    return distro_id, distro_like


def get_installed_dotfiles_version(config_root: Path | None = None) -> str | None:
    """Return the highest installed dotfiles version from ~/.config/hypr."""

    if config_root is None:
        config_root = Path(
            os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))
        )
    hypr_dir = config_root / "hypr"
    if not hypr_dir.is_dir():
        return None

    versions: list[tuple[tuple[int, int, int], str]] = []
    for p in hypr_dir.iterdir():
        if not p.is_file():
            continue
        name = p.name
        if not name.startswith("v"):
            continue
        m = re.fullmatch(r"v(\d+)\.(\d+)\.(\d+)", name)
        if not m:
            continue
        key = (int(m.group(1)), int(m.group(2)), int(m.group(3)))
        versions.append((key, name[1:]))

    if not versions:
        return None
    versions.sort(key=lambda x: x[0])
    return versions[-1][1]

"""Async environment probing for TUI startup.

This module provides async versions of system detection functions optimized for
running at application startup without blocking the UI.

NOTE: Some functions here intentionally duplicate logic from system.py:
- system.py contains synchronous versions used during installation (runtime)
- env_probe.py contains async versions used during app startup (probing)

This separation allows the TUI to remain responsive during initial environment
detection while still having synchronous access to the same information during
the actual installation process.
"""

from __future__ import annotations

import re
import os
from dataclasses import dataclass

from dots_tui.utils import run_cmd, which


@dataclass(frozen=True)
class ProbeResult:
    distro_id: str | None
    distro_like: tuple[str, ...]
    keyboard_layout: str | None
    express_supported: bool
    has_nvim: bool
    has_vim: bool


async def _capture(argv: list[str]) -> str:
    res = await run_cmd(argv)
    if res.returncode != 0:
        return ""
    return res.output


async def read_os_release() -> dict[str, str]:
    # Prefer reading the file directly to avoid subprocesses on startup.
    try:
        txt = "/etc/os-release"
        with open(txt, "r", encoding="utf-8", errors="replace") as f:
            lines = f.read().splitlines()
    except OSError:
        return {}

    out: dict[str, str] = {}
    for raw in lines:
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        out[k] = v.strip().strip('"')
    return out


async def detect_distro() -> tuple[str | None, tuple[str, ...]]:
    data = await read_os_release()
    distro_id = data.get("ID")
    id_like = data.get("ID_LIKE", "").strip()
    distro_like = tuple(s for s in re.split(r"\s+", id_like) if s)
    return distro_id, distro_like


async def detect_keyboard_layout() -> str | None:
    if which("localectl"):
        out = await _capture(["localectl", "status", "--no-pager"])
        m = re.search(r"^\s*X11\s+Layout:\s*(\S+)\s*$", out, re.MULTILINE)
        if m:
            return m.group(1)

    if which("setxkbmap"):
        out = await _capture(["setxkbmap", "-query"])
        m = re.search(r"^\s*layout:\s*(\S+)\s*$", out, re.MULTILINE)
        if m:
            return m.group(1)

    return None


async def get_installed_dotfiles_version() -> str | None:
    # Keep logic centralized in system.py; import lazily to avoid cycles.
    from dots_tui.logic.system import get_installed_dotfiles_version as _v

    return _v()


async def express_supported(min_version: str = "2.3.18") -> bool:
    from dots_tui.logic.system import version_gte

    v = await get_installed_dotfiles_version()
    if not v:
        return False
    return version_gte(v, min_version)


async def probe_environment() -> ProbeResult:
    distro_id, distro_like = await detect_distro()
    kb = await detect_keyboard_layout()
    exp = await express_supported()

    has_nvim = bool(which("nvim"))
    if not has_nvim:
        if os.path.exists("/usr/bin/nvim") or os.path.exists("/usr/local/bin/nvim"):
            has_nvim = True

    has_vim = bool(which("vim"))
    if not has_vim:
        if os.path.exists("/usr/bin/vim") or os.path.exists("/usr/local/bin/vim"):
            has_vim = True

    return ProbeResult(
        distro_id=distro_id,
        distro_like=distro_like,
        keyboard_layout=kb,
        express_supported=exp,
        has_nvim=has_nvim,
        has_vim=has_vim,
    )

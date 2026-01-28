from __future__ import annotations

import asyncio
import os
import re
import shlex
import shutil
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

# Re-export LogFn from models for backward compatibility
from dots_tui.logic.models import LogFn


# ANSI escape sequences come in 7-bit (ESC ...) and 8-bit (C1 control) forms.
_ANSI_CSI_RE = re.compile(r"(?:\x1b\[|\x9b)[0-?]*[ -/]*[@-~]")
_ANSI_OSC_RE = re.compile(r"(?:\x1b\]|\x9d).*?(?:\x07|\x1b\\)")
_ANSI_DCS_RE = re.compile(r"(?:\x1bP|\x90).*?(?:\x1b\\)")
_ANSI_SINGLE_RE = re.compile(r"\x1b[@-Z\\-_]")

_BROKEN_SGR_PREFIX_RE = re.compile(r"^(?:\[[0-9;]*m)+")
_BROKEN_SGR_PREFIX_SPACE_RE = re.compile(r"^(?:[0-9;]*m)+\s+")

_TUI_STRIP_TRANSLATION = {
    **{i: None for i in range(32) if i != 9},  # strip C0 controls except tab
    127: None,  # DEL
    **{i: None for i in range(128, 160)},  # strip C1 controls
    # Zero-width / bidi / formatting chars that can confuse terminal rendering.
    0x00AD: None,
    0x034F: None,
    0x061C: None,
    0x180E: None,
    0x200B: None,
    0x200C: None,
    0x200D: None,
    0x200E: None,
    0x200F: None,
    0x2028: None,
    0x2029: None,
    0x202A: None,
    0x202B: None,
    0x202C: None,
    0x202D: None,
    0x202E: None,
    0x2060: None,
    0x2066: None,
    0x2067: None,
    0x2068: None,
    0x2069: None,
    0xFEFF: None,
    0xFFF9: None,
    0xFFFA: None,
    0xFFFB: None,
}


def _sanitize_for_tui(line: str) -> str:
    # Best-effort sanitize subprocess output for Textual Log.

    if "\r" in line:
        # Keep only the last non-empty update for progress-like output.
        end = len(line)
        while True:
            idx = line.rfind("\r", 0, end)
            if idx == -1:
                line = line[:end]
                break
            seg = line[idx + 1 : end]
            if seg:
                line = seg
                break
            end = idx

    # Strip OSC (title/color) and CSI (color/cursor) sequences.
    line = _ANSI_OSC_RE.sub("", line)
    line = _ANSI_CSI_RE.sub("", line)
    line = _ANSI_DCS_RE.sub("", line)
    line = _ANSI_SINGLE_RE.sub("", line)

    # Some tools can emit broken / split SGR sequences; clean common remnants.
    line = _BROKEN_SGR_PREFIX_RE.sub("", line)
    line = _BROKEN_SGR_PREFIX_SPACE_RE.sub("", line)

    # Remove remaining control characters except tab.
    return line.translate(_TUI_STRIP_TRANSLATION)


@dataclass(frozen=True)
class CmdResult:
    argv: list[str]
    returncode: int
    output: str = ""


def is_root() -> bool:
    try:
        return os.geteuid() == 0
    except AttributeError:
        return False


def which(cmd: str) -> str | None:
    return shutil.which(cmd)


def fmt_cmd(argv: Iterable[str]) -> str:
    return " ".join(shlex.quote(a) for a in argv)


async def run_cmd(
    argv: list[str],
    *,
    cwd: Path | None = None,
    env: dict[str, str] | None = None,
    log: LogFn | None = None,
    input_text: str | None = None,
) -> CmdResult:
    """Run a command and stream stdout/stderr to log line-by-line."""
    if log:
        log_msg = f"$ {fmt_cmd(argv)}"
        if input_text:
            log_msg += "  < (stdin input)"
        log(log_msg)

    merged_env = os.environ.copy()
    if env:
        merged_env.update(env)

    merged_env.setdefault("NO_COLOR", "1")
    merged_env.setdefault("CLICOLOR", "0")
    merged_env.setdefault("CLICOLOR_FORCE", "0")
    merged_env.setdefault("PY_COLORS", "0")
    merged_env.setdefault("FORCE_COLOR", "0")

    process = await asyncio.create_subprocess_exec(
        *argv,
        cwd=str(cwd) if cwd else None,
        env=merged_env,
        stdin=asyncio.subprocess.PIPE if input_text else None,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.STDOUT,
    )

    if input_text and process.stdin:
        process.stdin.write(input_text.encode())
        process.stdin.close()  # EOF prevents hanging waiting for more input

    assert process.stdout is not None
    buf: list[str] = []
    try:
        while True:
            line = await process.stdout.readline()
            if not line:
                break
            decoded = line.decode(errors="replace").rstrip("\n")
            buf.append(decoded)
            if log:
                log(_sanitize_for_tui(decoded))
    finally:
        returncode = await process.wait()

    return CmdResult(argv=argv, returncode=returncode, output="\n".join(buf))

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from dots_tui.utils import CmdResult


@dataclass
class CmdCall:
    argv: list[str]
    cwd: Path | None


class CmdRecorder:
    def __init__(self) -> None:
        self.calls: list[CmdCall] = []

    async def run(
        self,
        argv: list[str],
        *,
        cwd: Path | None = None,
        env: dict[str, str] | None = None,
        log=None,
    ) -> CmdResult:
        # env is intentionally ignored; caller already sets process env.
        self.calls.append(CmdCall(argv=list(argv), cwd=cwd))
        if log is not None:
            log(f"$ {' '.join(argv)}")
        return CmdResult(argv=list(argv), returncode=0, output="")


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def touch_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def assert_is_symlink(path: Path) -> None:
    assert path.is_symlink(), f"Expected symlink: {path}"


def assert_is_file(path: Path) -> None:
    assert path.is_file(), f"Expected file: {path}"


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")

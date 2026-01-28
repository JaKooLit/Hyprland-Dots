from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Callable

import sys

import pytest


# Ensure src/ is importable when running tests without installing the package.
_ROOT = Path(__file__).resolve().parents[1]
_SRC = _ROOT / "src"
if str(_SRC) not in sys.path:
    sys.path.insert(0, str(_SRC))


@dataclass(frozen=True)
class FakeHome:
    home: Path
    config: Path
    data: Path
    pictures: Path
    copy_logs: Path


@pytest.fixture()
def fake_home(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> FakeHome:
    """Create an isolated HOME/XDG sandbox for installer runs."""

    home = tmp_path / "home"
    home.mkdir(parents=True)

    config = home / ".config"
    data = home / ".local" / "share"
    pictures = home / "Pictures"
    copy_logs = home / "Copy-Logs"

    config.mkdir(parents=True)
    data.mkdir(parents=True)
    pictures.mkdir(parents=True)
    copy_logs.mkdir(parents=True)

    monkeypatch.setenv("HOME", str(home))
    monkeypatch.setenv("XDG_CONFIG_HOME", str(config))
    monkeypatch.setenv("XDG_DATA_HOME", str(data))
    monkeypatch.setenv("XDG_PICTURES_DIR", str(pictures))

    # Patch Path.home() to return the fake home, so assert_safe_path passes.
    monkeypatch.setattr("dots_tui.logic.path_safety.Path.home", lambda: home)

    return FakeHome(
        home=home,
        config=config,
        data=data,
        pictures=pictures,
        copy_logs=copy_logs,
    )


@pytest.fixture()
def prompt_replace_yes() -> Callable[[str, Path], bool]:
    def _prompt(_name: str, _path: Path) -> bool:
        return True

    return _prompt


@pytest.fixture()
def prompt_confirm_yes() -> Callable[[str, str, str, bool], bool]:
    def _prompt(_message: str, _yes: str, _no: str, _default_yes: bool) -> bool:
        return True

    return _prompt


@pytest.fixture()
def prompt_confirm_no() -> Callable[[str, str, str, bool], bool]:
    def _prompt(_message: str, _yes: str, _no: str, _default_yes: bool) -> bool:
        return False

    return _prompt

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Literal, Protocol


# ============================================================================
# Type Aliases for Callback Functions
# ============================================================================

RunMode = Literal["install", "upgrade", "express", "update"]
ResolutionChoice = Literal["lt_1440p", "gte_1440p"]
ChassisType = Literal["desktop", "laptop"]
EditorChoice = Literal["nvim", "vim"]


class LogFn(Protocol):
    """Protocol for logging functions used throughout the installer.
    Example:
        def my_log(message: str) -> None:
            print(message)
    """

    def __call__(self, message: str) -> None: ...


class PromptReplaceFn(Protocol):
    """Protocol for prompting user to replace an existing config.
    Args:
        name: Name of the config (e.g., "rofi", "waybar")
        path: Path to the existing config directory
    Returns:
        True if user wants to replace, False to skip
    """

    def __call__(self, name: str, path: Path) -> bool: ...


class PromptConfirmFn(Protocol):
    """Protocol for prompting user for yes/no confirmation.
    Args:
        message: The question/message to display
        yes: Label for the "yes" button
        no: Label for the "no" button
        default_yes: Whether "yes" is the default choice

    Returns:
        True if user confirmed, False otherwise
    """

    def __call__(self, message: str, yes: str, no: str, default_yes: bool) -> bool: ...


class PromptPasswordFn(Protocol):
    """Protocol for prompting user for a password.

    Args:
        label: The prompt text to display

    Returns:
        The entered password or None if cancelled
    """

    def __call__(self, label: str) -> str | None: ...


@dataclass(frozen=True)
class InstallConfig:
    # User selections only. Runtime-derived fields live in InstallerState.
    run_mode: RunMode
    resolution: ResolutionChoice
    keyboard_layout: str
    clock_24h: bool
    default_editor: EditorChoice | None
    download_wallpapers: bool
    apply_sddm_wallpaper: bool
    enable_asus: bool
    enable_blueman: bool
    enable_ags: bool
    enable_quickshell: bool
    dry_run: bool = False


@dataclass(frozen=True)
class EnvironmentInfo:
    distro_id: str | None
    distro_like: tuple[str, ...]
    chassis: ChassisType
    is_nvidia: bool
    is_vm: bool
    is_nixos: bool
    installed_dotfiles_version: str | None


@dataclass(frozen=True)
class InstallerPaths:
    repo_root: Path
    copy_logs_dir: Path
    log_file: Path
    target_config_root: Path
    staging_root: Path | None


@dataclass(frozen=True)
class InstallerState:
    run_mode: RunMode
    selections: InstallConfig
    env: EnvironmentInfo
    paths: InstallerPaths

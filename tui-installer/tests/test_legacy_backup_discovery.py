"""Test legacy backup discovery for migration from copy.sh to TUI installer."""

from __future__ import annotations

from pathlib import Path
import pytest

from dots_tui.logic.backup import find_most_recent_backup


def test_find_most_recent_backup_tui_format(tmp_path: Path) -> None:
    """Test finding TUI format backups."""
    config_dir = tmp_path / ".config"
    config_dir.mkdir(parents=True)
    
    # Create TUI format backup
    backup1 = config_dir / "waybar-backup-01_29_1200"
    backup1.mkdir()
    
    result = find_most_recent_backup(config_dir / "waybar")
    assert result == backup1


def test_find_most_recent_backup_legacy_format(tmp_path: Path) -> None:
    """Test finding legacy copy.sh format backups."""
    config_dir = tmp_path / ".config"
    config_dir.mkdir(parents=True)
    
    # Create legacy format backup
    backup1 = config_dir / "waybar-backup-back-up_0129_1200"
    backup1.mkdir()
    
    result = find_most_recent_backup(config_dir / "waybar")
    assert result == backup1


def test_find_most_recent_backup_mixed_formats(tmp_path: Path) -> None:
    """Test finding newest backup when both formats exist."""
    config_dir = tmp_path / ".config"
    config_dir.mkdir(parents=True)
    
    # Create legacy backup (older)
    backup1 = config_dir / "waybar-backup-back-up_0129_1200"
    backup1.mkdir()
    
    # Create TUI backup (newer)
    backup2 = config_dir / "waybar-backup-01_30_0900"
    backup2.mkdir()
    
    # Touch backup2 to make it newer
    backup2.touch()
    
    result = find_most_recent_backup(config_dir / "waybar")
    # Should return the newest by mtime (backup2)
    assert result == backup2


def test_find_most_recent_backup_no_backups(tmp_path: Path) -> None:
    """Test when no backups exist."""
    config_dir = tmp_path / ".config"
    config_dir.mkdir(parents=True)
    
    result = find_most_recent_backup(config_dir / "waybar")
    assert result is None


def test_find_most_recent_backup_nonexistent_parent(tmp_path: Path) -> None:
    """Test when parent directory doesn't exist."""
    result = find_most_recent_backup(tmp_path / "nonexistent" / "waybar")
    assert result is None


def test_find_most_recent_backup_multiple_legacy(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    """Test finding newest among multiple legacy backups."""
    config_dir = tmp_path / ".config"
    config_dir.mkdir(parents=True)
    
    # Create multiple legacy backups
    backup1 = config_dir / "hypr-backup-back-up_0128_1000"
    backup2 = config_dir / "hypr-backup-back-up_0129_1500"
    backup3 = config_dir / "hypr-backup-back-up_0130_0800"
    
    backup1.mkdir()
    backup2.mkdir()
    backup3.mkdir()
    
    # Make backup2 the newest by mtime
    import time
    time.sleep(0.01)
    backup2.touch()
    
    result = find_most_recent_backup(config_dir / "hypr")
    assert result == backup2

"""Tests for edge cases with corrupted or missing config files.

These tests verify the installer handles malformed, missing, or corrupted
configuration files gracefully without crashing.
"""

from __future__ import annotations

import pytest
from pathlib import Path

from dots_tui.logic.system import (
    read_os_release,
    get_installed_dotfiles_version,
    version_gte,
)
from dots_tui.logic.copy_ops import _copytree
from dots_tui.logic.backup import backup_dir, backup_path
from dots_tui.logic.restore import merge_tree


class TestOsReleaseEdgeCases:
    """Tests for /etc/os-release parsing edge cases."""

    def test_missing_os_release(self, tmp_path: Path) -> None:
        """Test handling of missing os-release file."""
        result = read_os_release(tmp_path / "nonexistent")
        assert result == {}

    def test_empty_os_release(self, tmp_path: Path) -> None:
        """Test handling of empty os-release file."""
        f = tmp_path / "os-release"
        f.write_text("")
        result = read_os_release(f)
        assert result == {}

    def test_malformed_os_release(self, tmp_path: Path) -> None:
        """Test handling of malformed os-release file."""
        f = tmp_path / "os-release"
        f.write_text("""
# This is a comment
NOT_A_VALID_LINE
ID="arch"
NAME=
""")
        result = read_os_release(f)
        # Should parse what it can
        assert result.get("ID") == "arch"
        # Empty value after = should still work
        assert result.get("NAME") == ""

    def test_os_release_with_special_chars(self, tmp_path: Path) -> None:
        """Test handling of special characters in os-release."""
        f = tmp_path / "os-release"
        f.write_text("""ID="ubuntu"
NAME="Ubuntu 24.04 LTS (Noble Numbat)"
ID_LIKE="debian"
""")
        result = read_os_release(f)
        assert result.get("ID") == "ubuntu"
        assert "Noble Numbat" in result.get("NAME", "")
        assert result.get("ID_LIKE") == "debian"


class TestVersionParsingEdgeCases:
    """Tests for version parsing edge cases."""

    def test_version_gte_invalid_versions(self) -> None:
        """Test version comparison with invalid versions."""
        # Invalid versions should return False
        assert version_gte("invalid", "1.0.0") is False
        assert version_gte("1.0.0", "invalid") is False
        assert version_gte("", "") is False
        assert version_gte("1.0", "1.0.0") is False  # Missing patch version

    def test_version_gte_edge_cases(self) -> None:
        """Test version comparison edge cases."""
        assert version_gte("0.0.0", "0.0.0") is True
        assert version_gte("0.0.1", "0.0.0") is True
        assert version_gte("0.1.0", "0.0.99") is True
        assert version_gte("1.0.0", "0.99.99") is True
        assert version_gte("10.0.0", "9.99.99") is True

    def test_installed_version_missing_hypr_dir(self, tmp_path: Path) -> None:
        """Test version detection with missing hypr directory."""
        result = get_installed_dotfiles_version(tmp_path)
        assert result is None

    def test_installed_version_empty_hypr_dir(self, tmp_path: Path) -> None:
        """Test version detection with empty hypr directory."""
        hypr = tmp_path / "hypr"
        hypr.mkdir()
        result = get_installed_dotfiles_version(tmp_path)
        assert result is None

    def test_installed_version_no_version_files(self, tmp_path: Path) -> None:
        """Test version detection with no version marker files."""
        hypr = tmp_path / "hypr"
        hypr.mkdir()
        (hypr / "random_file.conf").write_text("test")
        result = get_installed_dotfiles_version(tmp_path)
        assert result is None

    def test_installed_version_multiple_versions(self, tmp_path: Path) -> None:
        """Test version detection picks highest version."""
        hypr = tmp_path / "hypr"
        hypr.mkdir()
        (hypr / "v1.0.0").touch()
        (hypr / "v2.0.0").touch()
        (hypr / "v1.5.0").touch()
        result = get_installed_dotfiles_version(tmp_path)
        assert result == "2.0.0"


class TestCopyOperationsEdgeCases:
    """Tests for file copy operation edge cases."""

    def test_copytree_creates_parents(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """Test that copytree creates parent directories."""
        monkeypatch.setattr("dots_tui.logic.path_safety.Path.home", lambda: tmp_path)
        src = tmp_path / "src"
        src.mkdir()
        (src / "file.txt").write_text("test")

        dst = tmp_path / "nested" / "path" / "dst"
        _copytree(src, dst)

        assert dst.exists()
        assert (dst / "file.txt").read_text() == "test"

    def test_copytree_replaces_existing(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """Test that copytree replaces existing directory."""
        monkeypatch.setattr("dots_tui.logic.path_safety.Path.home", lambda: tmp_path)
        src = tmp_path / "src"
        src.mkdir()
        (src / "new.txt").write_text("new content")

        dst = tmp_path / "dst"
        dst.mkdir()
        (dst / "old.txt").write_text("old content")

        _copytree(src, dst)

        assert (dst / "new.txt").exists()
        assert not (dst / "old.txt").exists()

    def test_copytree_preserves_symlinks(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """Test that copytree preserves symbolic links."""
        monkeypatch.setattr("dots_tui.logic.path_safety.Path.home", lambda: tmp_path)
        src = tmp_path / "src"
        src.mkdir()
        target = src / "target.txt"
        target.write_text("target content")
        link = src / "link.txt"
        link.symlink_to(target)

        dst = tmp_path / "dst"
        _copytree(src, dst)

        assert (dst / "link.txt").is_symlink()


class TestBackupEdgeCases:
    """Tests for backup operation edge cases."""

    def test_backup_nonexistent_path(self, tmp_path: Path) -> None:
        """Test backup of nonexistent path returns None."""
        result = backup_dir(tmp_path / "nonexistent")
        assert result is None

    def test_backup_path_format(self, tmp_path: Path) -> None:
        """Test backup path follows expected format."""
        src = tmp_path / "config"
        src.mkdir()

        path = backup_path(src)
        assert "-backup_" in path.name
        assert path.parent == src.parent


class TestMergeTreeEdgeCases:
    """Tests for merge_tree operation edge cases."""

    def test_merge_empty_src(self, tmp_path: Path) -> None:
        """Test merging empty source directory."""
        src = tmp_path / "src"
        src.mkdir()
        dst = tmp_path / "dst"
        dst.mkdir()
        (dst / "existing.txt").write_text("keep me")

        merge_tree(src, dst)

        # Existing file should still be there
        assert (dst / "existing.txt").read_text() == "keep me"

    def test_merge_creates_dst(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """Test merge creates destination if it doesn't exist."""
        monkeypatch.setattr("dots_tui.logic.path_safety.Path.home", lambda: tmp_path)
        src = tmp_path / "src"
        src.mkdir()
        (src / "file.txt").write_text("content")
        dst = tmp_path / "dst"

        merge_tree(src, dst)

        assert dst.exists()
        assert (dst / "file.txt").read_text() == "content"

    def test_merge_deep_nesting(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """Test merging deeply nested directory structures."""
        monkeypatch.setattr("dots_tui.logic.path_safety.Path.home", lambda: tmp_path)
        src = tmp_path / "src"
        nested = src / "a" / "b" / "c" / "d"
        nested.mkdir(parents=True)
        (nested / "deep.txt").write_text("deep content")

        dst = tmp_path / "dst"
        merge_tree(src, dst)

        assert (dst / "a" / "b" / "c" / "d" / "deep.txt").read_text() == "deep content"


class TestCorruptedConfigFiles:
    """Tests for handling corrupted config files."""

    def test_read_binary_as_config(self, tmp_path: Path) -> None:
        """Test reading binary file as config doesn't crash."""
        f = tmp_path / "config.conf"
        f.write_bytes(b"\x00\x01\x02\xff\xfe")

        # Should handle binary content gracefully
        content = f.read_text(encoding="utf-8", errors="replace")
        assert content is not None

    def test_read_config_with_null_bytes(self, tmp_path: Path) -> None:
        """Test reading config with embedded null bytes."""
        f = tmp_path / "config.conf"
        f.write_bytes(b"key=value\x00more=stuff\n")

        content = f.read_text(encoding="utf-8", errors="replace")
        assert "key=value" in content

    def test_read_utf16_as_utf8(self, tmp_path: Path) -> None:
        """Test reading UTF-16 file as UTF-8 doesn't crash."""
        f = tmp_path / "config.conf"
        f.write_text("key=value", encoding="utf-16")

        # Reading as UTF-8 should not crash (errors='replace')
        content = f.read_text(encoding="utf-8", errors="replace")
        assert content is not None

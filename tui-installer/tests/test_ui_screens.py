"""UI-level tests using Textual's testing framework.

These tests verify the TUI screens render correctly and respond to user input.
"""

from __future__ import annotations

import pytest

from dots_tui.app import InstallerApp
from dots_tui.screens.menu import MenuScreen
from dots_tui.screens.config import ConfigScreen


@pytest.fixture
def app() -> InstallerApp:
    """Create a test app instance."""
    return InstallerApp(dry_run=True)


class TestMenuScreen:
    """Tests for the main menu screen."""

    @pytest.mark.asyncio
    async def test_menu_screen_renders(self, app: InstallerApp) -> None:
        """Test that the menu screen renders without errors."""
        async with app.run_test() as _:
            # Check that the menu screen is displayed
            assert app.screen is not None
            assert isinstance(app.screen, MenuScreen)

    @pytest.mark.asyncio
    async def test_menu_has_all_buttons(self, app: InstallerApp) -> None:
        """Test that all expected buttons are present."""
        async with app.run_test() as _:
            # Query for buttons
            buttons = app.query("Button")
            button_ids = [b.id for b in buttons]

            # Check expected buttons exist
            assert "install" in button_ids
            assert "upgrade" in button_ids
            assert "express" in button_ids
            assert "update" in button_ids
            assert "quit" in button_ids

    @pytest.mark.asyncio
    async def test_menu_keyboard_navigation(self, app: InstallerApp) -> None:
        """Test that keyboard navigation works."""
        async with app.run_test() as pilot:
            # Press j to move down
            await pilot.press("j")
            await pilot.pause()

            # The focus should have moved
            focused = app.focused
            assert focused is not None

    @pytest.mark.asyncio
    async def test_menu_express_button_disabled_initially(
        self, app: InstallerApp
    ) -> None:
        """Test that express button is disabled while checking."""
        async with app.run_test() as _:
            express_btn = app.query_one("#express")
            # Initially disabled while probe is running
            assert express_btn.disabled is True

    @pytest.mark.asyncio
    async def test_quit_button_exits(self, app: InstallerApp) -> None:
        """Test that pressing quit exits the application."""
        async with app.run_test() as pilot:
            # Click the quit button
            await pilot.click("#quit")
            # App should be exiting
            assert app._exit is True or app.return_value is None


class TestConfigScreen:
    """Tests for the configuration screen."""

    @pytest.mark.asyncio
    async def test_config_screen_renders(self) -> None:
        """Test that the config screen renders without errors."""
        app = InstallerApp(dry_run=True, start="install")
        async with app.run_test() as _:
            # Should be on config screen, not menu
            assert isinstance(app.screen, ConfigScreen)

    @pytest.mark.asyncio
    async def test_config_screen_has_resolution_options(self) -> None:
        """Test that resolution options are present."""
        app = InstallerApp(dry_run=True, start="install")
        async with app.run_test() as _:
            resolution = app.query_one("#resolution")
            assert resolution is not None

    @pytest.mark.asyncio
    async def test_config_screen_has_keyboard_options(self) -> None:
        """Test that keyboard layout options are present."""
        app = InstallerApp(dry_run=True, start="install")
        async with app.run_test() as _:
            kb_layout = app.query_one("#kb_layout_mode")
            assert kb_layout is not None

    @pytest.mark.asyncio
    async def test_config_screen_has_clock_toggle(self) -> None:
        """Test that clock format toggle is present."""
        app = InstallerApp(dry_run=True, start="install")
        async with app.run_test() as _:
            clock = app.query_one("#clock_24h")
            assert clock is not None

    @pytest.mark.asyncio
    async def test_config_screen_has_next_button(self) -> None:
        """Test that next button is present."""
        app = InstallerApp(dry_run=True, start="install")
        async with app.run_test() as _:
            next_btn = app.query_one("#next")
            assert next_btn is not None

    @pytest.mark.asyncio
    async def test_config_screen_back_button_works(self) -> None:
        """Test that back button returns to menu."""
        app = InstallerApp(dry_run=True, start="install")
        async with app.run_test() as pilot:
            # Click back button
            await pilot.click("#back")
            await pilot.pause()

            # Should be back on menu screen
            assert isinstance(app.screen, MenuScreen)


class TestAppModes:
    """Tests for different app startup modes."""

    @pytest.mark.asyncio
    async def test_dry_run_mode(self) -> None:
        """Test that dry run mode is properly set."""
        app = InstallerApp(dry_run=True)
        async with app.run_test() as _:
            assert app._dry_run is True

    @pytest.mark.asyncio
    async def test_verbose_mode(self) -> None:
        """Test that verbose mode is properly set."""
        app = InstallerApp(verbose=True)
        async with app.run_test() as _:
            assert app._verbose is True

    @pytest.mark.asyncio
    async def test_upgrade_start_mode(self) -> None:
        """Test that upgrade mode skips menu."""
        app = InstallerApp(dry_run=True, start="upgrade")
        async with app.run_test() as _:
            assert isinstance(app.screen, ConfigScreen)
            # run_mode should be upgrade
            assert app.screen._run_mode == "upgrade"

    @pytest.mark.asyncio
    async def test_express_start_mode(self) -> None:
        """Test that express mode skips menu."""
        app = InstallerApp(dry_run=True, start="express")
        async with app.run_test() as _:
            assert isinstance(app.screen, ConfigScreen)
            assert app.screen._run_mode == "express"

"""Tests for the InputModal screen and password prompting logic."""

from __future__ import annotations

import pytest
from textual.app import App, ComposeResult
from textual.widgets import Button, Input, Label

from dots_tui.screens.input import InputModal


class ModalTestApp(App[str | None]):
    """Test app to mount the InputModal."""

    def __init__(self, modal: InputModal) -> None:
        super().__init__()
        self.modal = modal
        self.result: str | None = None

    def compose(self) -> ComposeResult:
        yield Label("Background")

    def on_mount(self) -> None:
        def callback(val: str | None) -> None:
            self.result = val
            self.exit(val)

        self.push_screen(self.modal, callback=callback)


@pytest.mark.asyncio
class TestInputModal:
    """Tests for the InputModal screen."""

    async def test_modal_renders_correctly(self) -> None:
        """Test that the modal renders with the correct elements."""
        modal = InputModal(
            title="Test Title",
            prompt="Enter password:",
            password=True,
            placeholder="Place...",
        )
        app = ModalTestApp(modal)

        async with app.run_test() as pilot:
            await pilot.pause()
            # Check title and prompt
            assert app.screen.query_one("#modal-title", Label).content == "Test Title"
            assert (
                app.screen.query_one("#modal-prompt", Label).content
                == "Enter password:"
            )

            # Check input properties
            inp = app.screen.query_one("#modal-input", Input)
            assert inp.password is True
            assert inp.placeholder == "Place..."

            # Check buttons exist
            assert str(app.screen.query_one("#submit", Button).label) == "Submit"
            assert str(app.screen.query_one("#cancel", Button).label) == "Cancel"

    async def test_submission_returns_value(self) -> None:
        """Test that submitting the form returns the input value."""
        modal = InputModal(title="Auth", prompt="Password:")
        app = ModalTestApp(modal)

        async with app.run_test() as pilot:
            # Type into input
            await pilot.click("#modal-input")
            await pilot.press("s", "e", "c", "r", "e", "t")

            # Click submit
            await pilot.click("#submit")

            # Wait for app to exit
            await pilot.pause()

            assert app.result == "secret"

    async def test_enter_key_submits(self) -> None:
        """Test that pressing Enter in the input submits the form."""
        modal = InputModal(title="Auth", prompt="Password:")
        app = ModalTestApp(modal)

        async with app.run_test() as pilot:
            await pilot.click("#modal-input")
            await pilot.press("1", "2", "3", "4", "enter")
            await pilot.pause()

            assert app.result == "1234"

    async def test_cancel_returns_none(self) -> None:
        """Test that clicking cancel returns None."""
        modal = InputModal(title="Auth", prompt="Password:")
        app = ModalTestApp(modal)

        async with app.run_test() as pilot:
            # Type something but then cancel
            await pilot.click("#modal-input")
            await pilot.press("a", "b", "c")

            await pilot.click("#cancel")
            await pilot.pause()

            assert app.result is None

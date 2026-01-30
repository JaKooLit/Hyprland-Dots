from __future__ import annotations

from textual import on
from textual.app import ComposeResult
from textual.containers import Container
from textual.screen import ModalScreen
from textual.widgets import Button, Input, Label


class InputModal(ModalScreen[str | None]):
    BINDINGS = [
        ("escape", "cancel", "Cancel"),
        ("q", "cancel", "Cancel"),
    ]

    def __init__(
        self,
        title: str,
        prompt: str,
        initial_value: str = "",
        password: bool = False,
        placeholder: str = "",
    ) -> None:
        super().__init__()
        self._title = title
        self._prompt = prompt
        self._initial = initial_value
        self._password = password
        self._placeholder = placeholder

    def compose(self) -> ComposeResult:
        with Container(id="modal-dialog"):
            yield Label(self._title, id="modal-title")
            yield Label(self._prompt, id="modal-prompt")
            yield Input(
                value=self._initial,
                password=self._password,
                placeholder=self._placeholder,
                id="modal-input",
            )
            with Container(id="modal-actions"):
                yield Button("Submit", variant="success", id="submit")
                yield Button("Cancel", variant="error", id="cancel")

    def on_mount(self) -> None:
        self.query_one("#modal-input", Input).focus()

    @on(Button.Pressed, "#submit")
    def action_submit(self) -> None:
        val = self.query_one("#modal-input", Input).value
        self.dismiss(val)

    @on(Button.Pressed, "#cancel")
    def action_cancel(self) -> None:
        self.dismiss(None)

    @on(Input.Submitted, "#modal-input")
    def on_input_submitted(self) -> None:
        self.action_submit()

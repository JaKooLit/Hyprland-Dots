from __future__ import annotations

from textual import events
from textual.containers import Container
from textual.screen import ModalScreen
from textual.widgets import Button, Static


class ConfirmScreen(ModalScreen[bool]):
    BINDINGS = [
        ("h,left", "no", "No"),
        ("l,right", "yes", "Yes"),
        ("j,down", "focus_next", "Next"),
        ("k,up", "focus_previous", "Prev"),
        ("enter", "accept", "Accept"),
        ("space", "accept", "Accept"),
        ("q", "no", "No"),
        ("escape", "no", "No"),
    ]

    def __init__(
        self,
        *,
        message: str,
        yes: str = "Yes",
        no: str = "No",
        default_yes: bool = True,
    ) -> None:
        super().__init__()
        self._message = message
        self._yes = yes
        self._no = no
        self._default_yes = default_yes

    def on_mount(self) -> None:
        btn_id = "yes" if self._default_yes else "no"
        try:
            self.query_one(f"#{btn_id}", Button).focus()
        except Exception:
            pass

    def compose(self):
        yield Container(
            Static(self._message, id="confirm-message"),
            Button(self._yes, id="yes", variant="success"),
            Button(self._no, id="no", variant="error"),
            id="confirm",
        )

    def on_key(self, event: events.Key) -> None:
        if event.key in {"j", "down"}:
            self.app.action_focus_next()
            event.stop()
            return
        if event.key in {"k", "up"}:
            self.app.action_focus_previous()
            event.stop()
            return

    def on_button_pressed(self, event: Button.Pressed) -> None:
        self.dismiss(event.button.id == "yes")

    def action_yes(self) -> None:
        self.dismiss(True)

    def action_no(self) -> None:
        self.dismiss(False)

    def action_accept(self) -> None:
        focused = self.app.focused
        if isinstance(focused, Button) and focused.id in {"yes", "no"}:
            self.dismiss(focused.id == "yes")
            return
        self.dismiss(self._default_yes)

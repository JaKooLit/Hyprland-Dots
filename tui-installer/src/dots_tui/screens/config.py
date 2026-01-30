from __future__ import annotations

from textual import events
from textual.containers import Container, VerticalScroll
from textual.screen import Screen
from textual.widgets import (
    Button,
    Checkbox,
    Input,
    Label,
    RadioButton,
    RadioSet,
    Static,
    Switch,
)

from dots_tui.logic.models import (
    EditorChoice,
    InstallConfig,
    ResolutionChoice,
    RunMode,
)
from dots_tui.logic.env_probe import ProbeResult
from dots_tui.screens.confirm import ConfirmScreen
from dots_tui.screens.progress import ProgressScreen


class ConfigScreen(Screen[None]):
    BINDINGS = [
        ("down", "focus_next", "Down"),
        ("up", "focus_previous", "Up"),
        ("tab", "focus_next", "Next"),
        ("shift+tab", "focus_previous", "Prev"),
        ("space", "activate", "Toggle/Select"),
        ("enter", "activate", "Toggle/Select"),
        ("h", "back", "Back"),
        ("q", "back", "Back"),
        ("escape", "back", "Back"),
    ]

    def __init__(self, *, run_mode: RunMode, dry_run: bool = False) -> None:
        super().__init__()
        self._run_mode: RunMode = run_mode
        self._dry_run = dry_run
        self._is_debian_ubuntu = False
        self._detected_keyboard_layout: str | None = None
        self._has_nvim = False
        self._has_vim = False
        # Track navigation for auto-advance feature
        self._last_nav_direction: str | None = None  # "down" or "up"
        self._prev_radio_states: dict[
            str, int
        ] = {}  # radioset_id -> previous pressed_index

    def compose(self):
        with Container(id="config-container"):
            yield Static(f"Configuration ({self._run_mode})", id="title")
            with VerticalScroll(id="scroll"):
                yield Static(
                    "These dotfiles are only supported on Hyprland v0.50+ on Ubuntu/Debian.",
                    id="distro-warning",
                    classes="hidden",
                )
                yield Checkbox(
                    "Continue anyway (required)",
                    id="distro-confirm",
                    value=False,
                    classes="hidden",
                )

                yield Label("Resolution")
                with RadioSet(id="resolution"):
                    yield RadioButton("< 1440p")
                    yield RadioButton(">= 1440p")

                yield Label("Keyboard layout")
                yield Static(
                    "STOP AND READ: Keyboard layout could not be detected.\n\n"
                    "Select 'Other' and enter a layout code manually (e.g. us, gb, ru).",
                    id="kb-unset-warning",
                    classes="hidden",
                )
                with RadioSet(id="kb_layout_mode"):
                    yield RadioButton("us", id="kb_us", value=True)
                    yield RadioButton("Other (enter manually)", id="kb_other")

                custom_val = self._detected_keyboard_layout or ""
                if custom_val == "us":
                    custom_val = ""
                yield Input(
                    value=custom_val,
                    placeholder="Enter layout code (e.g. kr, gb, ru)",
                    id="kb_layout_custom",
                    classes="hidden",
                )

                yield Label("Clock format")

                with Container(id="clock"):
                    yield Label("Use 12h")
                    yield Switch(value=True, id="clock_24h")
                    yield Label("Use 24h")

                yield Label("Default editor", id="editor_label", classes="hidden")
                with RadioSet(id="editor", classes="hidden"):
                    yield RadioButton("No change", id="editor_no_change", value=True)
                    yield RadioButton("nvim", id="editor_nvim")
                    yield RadioButton("vim", id="editor_vim")

                yield Label("Extras")
                yield Checkbox(
                    "Download additional wallpapers (1GB)", id="extra_wallpapers"
                )
                yield Checkbox("Apply wallpaper to SDDM", id="extra_sddm")
                yield Label("Additional Components")
                yield Checkbox(
                    "Blueman (Bluetooth Manager)", id="enable_blueman", value=True
                )
                yield Checkbox("Quickshell", id="enable_quickshell", value=True)
                yield Checkbox("AGS (Aylur's GTK Shell)", id="enable_ags", value=False)
                yield Checkbox(
                    "AsusCtl (ROG Control Center)", id="enable_asus", value=False
                )

            yield Static("", id="validation")

            with Container(id="actions"):
                yield Button("Next", id="next", variant="success")
                yield Button("Back", id="back")

            yield Static("hjkl/arrows/tab: nav • space: toggle • q: back", id="help")

    def _apply_distro_warning(self) -> None:
        """Show distro warning for Debian/Ubuntu users."""
        if not self._is_debian_ubuntu:
            return
        try:
            warn = self.query_one("#distro-warning")
            confirm = self.query_one("#distro-confirm")
            warn.display = True
            confirm.display = True
        except Exception as e:
            self.log.warning(f"Failed to show distro warning: {e}")

    def _apply_keyboard_defaults(self) -> None:
        """Configure keyboard layout UI based on detected layout."""
        # Set custom input default value.
        try:
            inp = self.query_one("#kb_layout_custom", Input)
            if not inp.value:
                custom_val = self._detected_keyboard_layout or ""
                if custom_val == "us":
                    custom_val = ""
                inp.value = custom_val
        except Exception as e:
            self.log.warning(f"Failed to set keyboard input default: {e}")

        # Auto-select keyboard layout mode based on detection.
        try:
            kb_mode = self.query_one("#kb_layout_mode", RadioSet)
            kb_us = self.query_one("#kb_us", RadioButton)
            kb_other = self.query_one("#kb_other", RadioButton)
            inp = self.query_one("#kb_layout_custom", Input)
            warn = self.query_one("#kb-unset-warning", Static)

            detected = (self._detected_keyboard_layout or "").strip()
            if not detected:
                # No layout detected - force manual entry.
                warn.display = True
                kb_other.value = True
                inp.value = ""
                inp.remove_class("hidden")
                inp.focus()
            elif detected != "us":
                # Non-US layout detected - pre-fill and show input.
                warn.display = False
                kb_other.value = True
                inp.value = detected
                inp.remove_class("hidden")
            else:
                # US layout detected - select US radio button.
                warn.display = False
                kb_us.value = True
                inp.add_class("hidden")

            # Keep internal pressed_button state consistent.
            _ = kb_mode.pressed_button
        except Exception as e:
            self.log.warning(f"Failed to configure keyboard layout UI: {e}")

    def _apply_editor_defaults(self) -> None:
        """Configure editor selection UI based on available editors."""
        try:
            editor_label = self.query_one("#editor_label")
            editor_radioset = self.query_one("#editor", RadioSet)
            if self._has_nvim or self._has_vim:
                editor_label.remove_class("hidden")
                editor_radioset.remove_class("hidden")
                self.query_one("#editor_nvim").display = self._has_nvim
                self.query_one("#editor_vim").display = self._has_vim
                # Auto-select best available: nvim > vim > no change
                if self._has_nvim:
                    self.query_one("#editor_nvim", RadioButton).value = True
                elif self._has_vim:
                    self.query_one("#editor_vim", RadioButton).value = True
            else:
                editor_label.add_class("hidden")
                editor_radioset.add_class("hidden")
        except Exception as e:
            self.log.warning(f"Failed to configure editor UI: {e}")

    def on_mount(self) -> None:
        if self._run_mode == "express":
            try:
                # Express mode skips wallpaper download logic, so hide the option.
                self.query_one("#extra_wallpapers").display = False
            except Exception as e:
                self.log.warning(
                    f"Failed to hide extra_wallpapers in express mode: {e}"
                )

        async def apply_probe() -> None:
            get_probe = getattr(self.app, "get_probe")
            probe: ProbeResult = await get_probe()

            # Extract probe results into instance state.
            ids = {x.lower() for x in ([probe.distro_id] if probe.distro_id else [])}
            ids |= {x.lower() for x in probe.distro_like}
            self._is_debian_ubuntu = bool(ids & {"debian", "ubuntu"})
            self._detected_keyboard_layout = probe.keyboard_layout
            self._has_nvim = probe.has_nvim
            self._has_vim = probe.has_vim

            # Apply UI updates based on probe results.
            self._apply_distro_warning()
            self._apply_keyboard_defaults()
            self._apply_editor_defaults()

        self.run_worker(apply_probe, exclusive=True)

        # Default resolution is < 1440p.
        rs = self.query_one("#resolution", RadioSet)
        buttons = list(rs.query(RadioButton))
        if len(buttons) >= 2:
            # Textual's RadioSet exposes pressed_index as read-only; set the
            # pressed RadioButton value instead.
            buttons[0].value = True

        rs.focus()

    def _go_back(self) -> None:
        """Return to menu when possible; otherwise switch to a new menu.

        When ConfigScreen is reached from MenuScreen, pop_screen() restores the
        existing menu. When the app starts directly in a config mode (e.g.
        --upgrade), popping would return to Textual's default screen.
        """

        from dots_tui.screens.menu import MenuScreen

        prev = self.app.screen_stack[-2] if len(self.app.screen_stack) >= 2 else None
        if isinstance(prev, MenuScreen):
            self.app.pop_screen()
        else:
            self.app.switch_screen(MenuScreen(dry_run=self._dry_run))

    def action_back(self) -> None:
        self._go_back()

    def action_activate(self) -> None:
        focused = self.app.focused
        if focused is None:
            return

        if isinstance(focused, Button):
            focused.press()
            return

        if isinstance(focused, (Checkbox, Switch, RadioButton)):
            focused.toggle()
            return

        action_press = getattr(focused, "action_press", None)
        if callable(action_press):
            action_press()
            return

    def on_key(self, event: events.Key) -> None:
        # Vim-style navigation:
        # - Outside RadioSets, use j/k/arrows to move focus between widgets.
        # - Inside RadioSets, j/k/arrows navigate options with auto-advance at boundaries.
        focused = self.app.focused

        # Handle navigation inside RadioSet
        if event.key in {"j", "k", "down", "up"} and isinstance(focused, RadioSet):
            buttons = list(focused.query(RadioButton))
            # Get enabled (visible) buttons only
            enabled_buttons = [b for b in buttons if b.display and not b.disabled]

            # Use _selected (cursor position) instead of pressed_index (filled circle)
            # _selected tracks where the visual highlight/cursor is
            cursor_idx = getattr(focused, "_selected", None)

            if cursor_idx is not None and enabled_buttons and len(enabled_buttons) > 0:
                # Find cursor position within enabled buttons
                try:
                    cursor_button = (
                        buttons[cursor_idx] if cursor_idx < len(buttons) else None
                    )
                    if cursor_button and cursor_button in enabled_buttons:
                        enabled_idx = enabled_buttons.index(cursor_button)
                    else:
                        enabled_idx = -1
                except (IndexError, ValueError):
                    enabled_idx = -1

                is_going_down = event.key in {"j", "down"}
                at_last = enabled_idx == len(enabled_buttons) - 1
                at_first = enabled_idx == 0

                # At boundary: advance to next/previous widget
                if is_going_down and at_last:
                    event.prevent_default()
                    event.stop()
                    self.app.action_focus_next()
                    return

                if not is_going_down and at_first:
                    event.prevent_default()
                    event.stop()
                    # At top-most radioset, wrap to Back so focus doesn't disappear.
                    if focused.id == "resolution":
                        self.query_one("#back", Button).focus()
                    else:
                        self.app.action_focus_previous()
                    return

            # Not at boundary: navigate within RadioSet
            if event.key in {"j", "down"}:
                focused.action_next_button()
            else:
                focused.action_previous_button()
            event.stop()
            return

        # Outside RadioSet: j/k/arrows move between widgets
        if event.key in {"j", "down"}:
            if isinstance(focused, Button) and focused.id == "back":
                rs = self.query_one("#resolution", RadioSet)
                rs.focus()
                buttons = list(rs.query(RadioButton))
                enabled_buttons = [b for b in buttons if b.display and not b.disabled]
                if enabled_buttons:
                    action_first = getattr(rs, "action_first_button", None)
                    if callable(action_first):
                        action_first()
                    else:
                        setattr(rs, "_selected", buttons.index(enabled_buttons[0]))
                        rs.refresh()
                event.stop()
                return
            self.app.action_focus_next()
            event.stop()
            return

        if event.key in {"k", "up"}:
            self.app.action_focus_previous()
            event.stop()
            return

        # Tab navigation
        if event.key == "tab":
            self.app.action_focus_next()
            event.stop()
            return

        if event.key == "shift+tab":
            self.app.action_focus_previous()
            event.stop()
            return

    def on_radio_set_changed(self, event: RadioSet.Changed) -> None:
        if event.radio_set.id == "kb_layout_mode":
            is_other = event.pressed.id == "kb_other"
            inp = self.query_one("#kb_layout_custom", Input)
            if is_other:
                inp.remove_class("hidden")
                inp.focus()
            else:
                inp.add_class("hidden")

    def on_checkbox_changed(self, event: Checkbox.Changed) -> None:
        if event.checkbox.id == "extra_wallpapers" and event.value:
            self.notify(
                "A number of these wallpapers are AI generated or enhanced.",
                title="Note",
                severity="information",
                timeout=4.0,
            )

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "back":
            self._go_back()
            return
        if event.button.id != "next":
            return

        if self._is_debian_ubuntu:
            confirm = self.query_one("#distro-confirm", Checkbox).value
            if not confirm:
                msg = "Ubuntu/Debian detected. You must confirm you want to continue anyway."
                self.query_one("#validation", Static).update(msg)
                self.query_one("#distro-confirm", Checkbox).focus()
                return

        rs = self.query_one("#resolution", RadioSet)

        kb_mode = self.query_one("#kb_layout_mode", RadioSet)
        if kb_mode.pressed_button and kb_mode.pressed_button.id == "kb_us":
            kb = "us"
        else:
            kb = self.query_one("#kb_layout_custom", Input).value.strip()

        if not kb:
            self.query_one("#validation", Static).update(
                "Please enter a keyboard layout (e.g. us)."
            )
            inp = self.query_one("#kb_layout_custom", Input)
            inp.remove_class("hidden")
            inp.focus()
            return

        clock_24h = self.query_one("#clock_24h", Switch).value

        default_editor: EditorChoice | None = None
        if self._has_nvim or self._has_vim:
            try:
                ers = self.query_one("#editor", RadioSet)
                pressed = ers.pressed_button
                if pressed is not None and pressed.id == "editor_nvim":
                    default_editor = "nvim"
                elif pressed is not None and pressed.id == "editor_vim":
                    default_editor = "vim"
            except Exception:
                default_editor = None
        dl_walls = self.query_one("#extra_wallpapers", Checkbox).value
        sddm = self.query_one("#extra_sddm", Checkbox).value

        enable_asus = self.query_one("#enable_asus", Checkbox).value
        enable_blueman = self.query_one("#enable_blueman", Checkbox).value
        enable_ags = self.query_one("#enable_ags", Checkbox).value
        enable_quickshell = self.query_one("#enable_quickshell", Checkbox).value

        resolution: ResolutionChoice = (
            "gte_1440p" if rs.pressed_index == 1 else "lt_1440p"
        )

        cfg = InstallConfig(
            run_mode=self._run_mode,
            resolution=resolution,
            keyboard_layout=kb,
            clock_24h=clock_24h,
            default_editor=default_editor,
            download_wallpapers=dl_walls,
            apply_sddm_wallpaper=sddm,
            enable_asus=enable_asus,
            enable_blueman=enable_blueman,
            enable_ags=enable_ags,
            enable_quickshell=enable_quickshell,
            dry_run=self._dry_run,
        )

        def after_confirm(ok: bool | None) -> None:
            if ok is True:
                self.app.push_screen(ProgressScreen.for_install(cfg))
            else:
                self.query_one("#validation", Static).update(
                    "Keyboard layout not confirmed. Please re-enter it."
                )
                kb_mode = self.query_one("#kb_layout_mode", RadioSet)
                if kb_mode.pressed_button and kb_mode.pressed_button.id == "kb_us":
                    kb_mode.focus()
                else:
                    self.query_one("#kb_layout_custom", Input).focus()

        self.app.push_screen(
            ConfirmScreen(
                message=f"Current keyboard layout is: {kb}\n\nIs this correct?"
            ),
            callback=after_confirm,
        )

# Hyprland-Dots TUI Installer

Python/Textual TUI installer intended to replace the legacy bash installer flow for the [Hyprland-Dots](https://github.com/prasanthrangan/hyprdots) repository.

## Features

- **Guided TUI**: Interactive menu, configuration, and real-time progress logging.
- **Run Modes**:
  - `Install`: Fresh installation with full configuration.
  - `Update`: Pull latest changes from git.
  - `Upgrade`: Quick upgrade of configs (skips some steps).
  - `Express`: Automatic upgrade with default selections.
- **Robust Sudo Handling**: Handles privileged operations (SDDM themes) with interactive password prompting or `NOPASSWD` support to keep the TUI responsive.
- **Standalone Binary**: Can be compiled to a single binary for "curl-to-run" usage.

## Requirements

- **Linux** (Arch/Debian/Fedora/OpenSUSE supported via system detection logic)
- **Python 3.11+** (for local development)
- **`uv`** (modern Python dependency manager)

## Quick Start (Development)

1. Clone the repository and navigate to root:

   ```bash
   git clone https://github.com/jakoolit/hyprland-dots.git
   cd hyprland-dots/tui-installer
   ```

2. Sync dependencies and run:

   ```bash
   uv sync --locked --dev
   uv run python -m dots_tui
   ```

### Command Line Flags

The installer supports several flags for automation and debugging:

| Flag | Description |
|------|-------------|
| `--dry-run` | Run the flow without making filesystem changes. |
| `--verbose`, `-v` | Enable detailed debug logging for development. |
| `--upgrade` | Skip menu directly to Upgrade mode. |
| `--express-upgrade` | Skip menu directly to Express mode (defaults applied). |
| `--update` | Skip menu directly to Repo Update mode. |

### Viewing Debug Logs

When running with `--verbose`, logs are sent to the Textual DevTools console. To view them:

1. Open a second terminal window.
2. Run the console listener:

   ```bash
   uv run textual console
   ```

3. Run the installer in your main terminal:

   ```bash
   uv run python -m dots_tui --verbose
   ```

## Sudo Privileges & Permissions

To enable all features (specifically **SDDM theme patching** and **system-wide wallpaper application**), the installer requires `sudo` privileges.

1. **Interactive Prompt**: The installer will attempt `sudo -n` first. If that fails, it will **prompt you for your password** using a secure TUI dialog.
2. **Unattended Mode**: For a fully automated experience, you can configure `NOPASSWD` in `sudoers`:

   ```bash
   your_username ALL=(ALL) NOPASSWD: ALL
   ```

3. **Fallback**: If authentication fails or is cancelled, privileged steps are safely skipped, and the installation proceeds.

## Testing

This project includes a comprehensive test suite covering UI screens, edge cases, and input logic.

```bash
# Run all tests
uv run pytest
# Run with verbose output
uv run pytest -v
```

Tests allow verifying the UI logic without needing a full graphical environment.

## Building Standalone Binary

You can compile the installer into a single, dependency-free binary using PyInstaller.

```bash
uv sync --locked --dev
uv run pyinstaller build.spec
```

**Artifact**: `dist/dots-tui`

*Note: Build on the oldest Linux distro you intend to support (e.g., Ubuntu 20.04) to ensure glibc compatibility for users.*

## Project Structure

```text
.
├── build.spec                     # PyInstaller build definition
├── pyproject.toml                 # Project metadata + dependencies
├── uv.lock                        # Locked dependency graph
├── src/dots_tui/
│   ├── __main__.py                # Entry point (CLI arg parsing)
│   ├── app.py                     # Main Textual App & Global State
│   ├── installer.tcss             # CSS Styles for TUI
│   ├── utils.py                   # Shared utilities (asyncio, logging)
│   ├── screens/
│   │   ├── menu.py                # Main Menu
│   │   ├── config.py              # Configuration Form
│   │   ├── progress.py            # Install execution & logging
│   │   ├── confirm.py             # Binary Yes/No Dialog
│   │   └── input.py               # Password Input Dialog
│   └── logic/
│       ├── orchestrator.py        # Central Install Logic Engine
│       ├── copy_ops.py            # File operations
│       ├── system.py              # Distro detection / System Checks
│       └── models.py              # Data classes & Type definitions
├── tests/
│   ├── test_ui_screens.py         # App navigation & rendering tests
│   ├── test_edge_cases.py         # Config corruption & logic tests
│   └── test_input_modal.py        # Password prompt tests
└── scripts/                       # CI/CD helpers
```

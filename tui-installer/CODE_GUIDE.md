# Codebase Guide: Hyprland-Dots TUI Installer

--- (AI Generated) ---
--- This must be deleted after testing ---

Welcome! This document provides a roadmap to help you read and understand the source code of this TUI (Terminal User Interface) installer.

## 1. Project Overview

This application is a Python-based installer for Hyprland dotfiles. It uses:

- **[Textual](https://textual.textualize.io/):** For the TUI framework.
- **Python Asyncio:** For non-blocking operations (especially file I/O and shell commands).
- **Git:** For managing the dotfiles repository updates.

## 2. Directory Structure

The source code is located in `src/dots_tui`.

```text
src/dots_tui/
├── __main__.py          # Entry point (CLI arg parsing)
├── app.py               # Main Textual App class
├── installer.tcss       # Stylesheet for the TUI
├── utils.py             # Shared utilities (asyncio, logging)
├── screens/             # UI Screens (Views)
│   ├── menu.py          # Main Menu
│   ├── config.py        # Configuration Form
│   ├── progress.py      # Installation Progress Log
│   ├── confirm.py       # Generic Confirmation Dialog
│   └── input.py         # Password Input Dialog
└── logic/               # Business Logic
    ├── orchestrator.py  # MAIN logic controller (The "Brain")
    ├── env_probe.py     # System detection (distro, GPU, etc.)
    ├── models.py        # Data classes (Config, State)
    ├── system.py        # System utilities (distro ID, version checks)
    ├── backup.py        # Backup logic
    ├── restore.py       # Restoration logic
    └── ...              # Other helpers (copy_ops, dedupe, etc.)
```

## 3. Recommended Reading Order

To understand the flow of the application, follow this path:

### Step 1: Entry Point

Start with **`src/dots_tui/__main__.py`**.

- **Goal:** See how command-line arguments (like `--dry-run`, `--upgrade`) are parsed and how the app is launched.

### Step 2: The Application Core

Next, read **`src/dots_tui/app.py`**.

- **Goal:** Understand the `InstallerApp` class. Look at the `on_mount` method to see how it decides which screen to show first (Menu vs. Config vs. Progress).

### Step 3: The User Interface (Screens)

Check out the screens in `src/dots_tui/screens/`.

- **`menu.py`**: The main landing screen. See how buttons trigger actions.
- **`config.py`**: The settings form. See how user choices are captured into an `InstallConfig` object.
- **`progress.py`**: The execution screen. This is where the UI hands off control to the backend logic.

### Step 4: The "Brain" (Orchestrator)

This is the most important file for the actual installation process: **`src/dots_tui/logic/orchestrator.py`**.

- **Goal:** Read the `run_install` method. It acts as a script, executing steps sequentially:
    1. Prepares directories.
    2. Stages files.
    3. Applies tweaks (Nvidia, VM, etc.).
    4. Copies configs (Phase 1 & 2).
    5. Finalizes (symlinks, permissions).

### Step 5: Logic Helpers

Dive into specific logic files as needed:

- **`logic/env_probe.py`**: How we detect if the system is suitable (e.g., "Can we run express mode?").
- **`logic/system.py`**: Distro detection and version comparison logic.
- **`logic/copy_ops.py`**: The actual file copying commands.

## 4. Key Concepts

- **Dry Run:** The app supports a `--dry-run` flag. In `orchestrator.py`, you'll see checks for `if config.dry_run:`. Instead of executing commands, it often adds them to a `PlanCollector` to just print what *would* happen.
- **Express Mode:** A faster upgrade path that skips prompts. Logic for this is scattered in `orchestrator.py` (checking `config.run_mode == "express"`).
- **Parity:** The code is designed to match the behavior of the original Bash installation scripts (`install.sh`, `restore_fnt.sh`, etc.) as closely as possible.

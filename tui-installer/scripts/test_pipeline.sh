#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo "==> Sync deps (locked)"
uv sync --locked --dev

echo "==> Type check (basedpyright)"
uv run python -m basedpyright src

echo "==> Lint (ruff)"
uv run ruff check src tests

echo "==> Format check (ruff)"
uv run ruff format --check src tests

echo "==> Tests (pytest)"
# Ensure "tests" can be imported (tests/helpers.py) when executing as a project.
# Also avoid writing pytest cache files.
PYTHONPATH="${PWD}" uv run python -m pytest -q -p no:cacheprovider

echo "==> OK"

#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/plugin-runtime.sh"

PYTHON_BIN_FILE="$(mktemp)"
"$SCRIPT_DIR/plugin-bootstrap.sh" >"$PYTHON_BIN_FILE"
PYTHON_BIN="$(cat "$PYTHON_BIN_FILE")"
rm -f "$PYTHON_BIN_FILE"
MEMPALACE_BIN="$(dirname "$PYTHON_BIN")/mempalace"

export PYTHON_BIN
export MEMPALACE_BIN
export MEMPALACE_BIN_OVERRIDE="$MEMPALACE_BIN"
export PATH="$(dirname "$PYTHON_BIN"):$PATH"

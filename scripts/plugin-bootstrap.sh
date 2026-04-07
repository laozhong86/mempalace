#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PLUGIN_DATA="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugins-data/mempalace}"
RUNTIME_DIR="$PLUGIN_DATA/runtime"
VENV_DIR="$RUNTIME_DIR/venv"
LOG_DIR="$PLUGIN_DATA/logs"
LOG_FILE="$LOG_DIR/bootstrap.log"
STAMP_FILE="$RUNTIME_DIR/install-stamp"

mkdir -p "$LOG_DIR" "$RUNTIME_DIR"

PYTHON_CMD="${MEMPALACE_PYTHON_COMMAND:-${CLAUDE_PLUGIN_OPTION_PYTHON_COMMAND:-python3}}"

PLUGIN_VERSION="$("$PYTHON_CMD" - <<'PY' "$PLUGIN_ROOT/.claude-plugin/plugin.json"
import json
import pathlib
import sys

plugin_json = pathlib.Path(sys.argv[1])
data = json.loads(plugin_json.read_text())
print(data.get("version", "0.0.0"))
PY
)"

need_install=0
if [[ ! -x "$VENV_DIR/bin/python" ]]; then
  need_install=1
elif [[ ! -f "$STAMP_FILE" ]]; then
  need_install=1
else
  stamp_contents="$(cat "$STAMP_FILE" 2>/dev/null || true)"
  if [[ "$stamp_contents" != "$PLUGIN_VERSION|$PLUGIN_ROOT" ]]; then
    need_install=1
  fi
fi

if [[ "$need_install" == "1" ]]; then
  rm -rf "$VENV_DIR"
  "$PYTHON_CMD" -m venv "$VENV_DIR" >>"$LOG_FILE" 2>&1
  "$VENV_DIR/bin/python" -m pip install --upgrade pip >>"$LOG_FILE" 2>&1
  "$VENV_DIR/bin/python" -m pip install -e "$PLUGIN_ROOT" >>"$LOG_FILE" 2>&1
  printf '%s|%s' "$PLUGIN_VERSION" "$PLUGIN_ROOT" > "$STAMP_FILE"
fi

printf '%s\n' "$VENV_DIR/bin/python"

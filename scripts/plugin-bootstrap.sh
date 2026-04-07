#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/plugin-runtime.sh"

PLUGIN_ROOT="$(plugin_runtime_resolve_root)"
PLUGIN_DATA="$(plugin_runtime_resolve_data_dir)"
RUNTIME_DIR="$PLUGIN_DATA/runtime"
VENV_DIR="$RUNTIME_DIR/venv"
LOG_DIR="$PLUGIN_DATA/logs"
LOG_FILE="$LOG_DIR/bootstrap.log"
STAMP_FILE="$RUNTIME_DIR/install-stamp"

mkdir -p "$LOG_DIR" "$RUNTIME_DIR"

PYTHON_CMD="$(
  plugin_runtime_first_set \
    MEMPALACE_PYTHON_COMMAND \
    CLAUDE_PLUGIN_OPTION_PYTHON_COMMAND \
    CODEX_PLUGIN_OPTION_PYTHON_COMMAND \
  || printf 'python3'
)"

PLUGIN_MANIFEST="$(plugin_runtime_resolve_manifest_path)"

PLUGIN_VERSION="$("$PYTHON_CMD" - <<'PY' "$PLUGIN_MANIFEST"
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
  printf '%s|%s\n' "$PLUGIN_VERSION" "$PLUGIN_ROOT" > "$STAMP_FILE"
fi

printf '%s\n' "$VENV_DIR/bin/python"

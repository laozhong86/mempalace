#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/plugin-runtime.sh"

mkdir -p "$LOG_DIR" "$RELEASES_DIR"

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

exec 9>"$LOCK_FILE"
LOCK_DIR="${LOCK_FILE}.lockdir"
release_dir=""
cleanup() {
  rmdir "$LOCK_DIR" 2>/dev/null || true
  if [ -n "${release_dir:-}" ]; then
    rm -rf "$release_dir" 2>/dev/null || true
  fi
}

while ! mkdir "$LOCK_DIR" 2>/dev/null; do
  if [ -f "$LOCK_DIR/pid" ]; then
    lock_pid="$(cat "$LOCK_DIR/pid" 2>/dev/null || true)"
    if [ -n "$lock_pid" ] && ! kill -0 "$lock_pid" 2>/dev/null; then
      rm -f "$LOCK_DIR/pid" 2>/dev/null || true
      rmdir "$LOCK_DIR" 2>/dev/null || true
      continue
    fi
  fi
  sleep 0.1
done
printf '%s\n' "$$" > "$LOCK_DIR/pid"
trap cleanup EXIT

if [[ -x "$CURRENT_DIR/bin/python" ]] && [[ -f "$CURRENT_DIR/install-stamp" ]]; then
  stamp_contents="$(cat "$CURRENT_DIR/install-stamp" 2>/dev/null || true)"
  if [[ "$stamp_contents" == "$PLUGIN_VERSION|$PLUGIN_ROOT" ]]; then
    printf '%s\n' "$CURRENT_DIR/bin/python"
    exit 0
  fi
fi

release_dir="$(mktemp -d "$RELEASES_DIR/release.XXXXXX")"

"$PYTHON_CMD" -m venv "$release_dir" >>"$LOG_DIR/bootstrap.log" 2>&1
"$release_dir/bin/python" -m pip install --upgrade pip >>"$LOG_DIR/bootstrap.log" 2>&1
"$release_dir/bin/python" -m pip install "$PLUGIN_ROOT" >>"$LOG_DIR/bootstrap.log" 2>&1
printf '%s|%s\n' "$PLUGIN_VERSION" "$PLUGIN_ROOT" > "$release_dir/install-stamp"

ln -sfn "$release_dir" "$CURRENT_DIR"
rmdir "$LOCK_DIR" 2>/dev/null || true
trap - EXIT

printf '%s\n' "$CURRENT_DIR/bin/python"

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/plugin-runtime.sh"
PYTHON_BIN="$("$SCRIPT_DIR/plugin-bootstrap.sh")"

hooks_ok="yes"
[ -x "$PLUGIN_ROOT/hooks/mempal_save_hook.sh" ] || hooks_ok="no"
[ -x "$PLUGIN_ROOT/hooks/mempal_precompact_hook.sh" ] || hooks_ok="no"
[ -x "$PLUGIN_ROOT/hooks/mempal_session_start_hook.sh" ] || hooks_ok="no"

import_ok="no"
if "$PYTHON_BIN" - <<'PY'
from mempalace import __name__ as package_name
assert package_name == "mempalace"
PY
then
  import_ok="yes"
fi

palace_ok="no"
if [ -d "$MEMPALACE_PALACE_PATH" ]; then
  palace_ok="yes"
fi

log_dir_ok="no"
mkdir -p "$LOG_DIR" && touch "$LOG_DIR/.doctor-write-test" && log_dir_ok="yes"

if [ "$hooks_ok" = "no" ] || [ "$import_ok" = "no" ] || [ "$log_dir_ok" = "no" ]; then
  echo "runtime_python=$PYTHON_BIN"
  echo "palace_path=$MEMPALACE_PALACE_PATH"
  echo "palace_path_exists=$palace_ok"
  echo "hooks_executable=$hooks_ok"
  echo "mcp_import=$import_ok"
  echo "writable_log_dir=$log_dir_ok"
  exit 1
fi

echo "runtime_python=$PYTHON_BIN"
echo "palace_path=$MEMPALACE_PALACE_PATH"
echo "palace_path_exists=$palace_ok"
echo "hooks_executable=$hooks_ok"
echo "mcp_import=$import_ok"
echo "writable_log_dir=$log_dir_ok"

#!/bin/bash
# MEMPALACE SESSION START HOOK — Inject wake-up context into Claude Code
#
# Claude Code "SessionStart" hook.
# 1. Loads the current MemPalace wake-up context
# 2. Injects concise workflow guidance for search / diary / knowledge graph
# 3. Keeps startup context tied to the same palace as MCP reads

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

if [ -x "$REPO_DIR/.venv/bin/mempalace" ]; then
  MEMPALACE_BIN="$REPO_DIR/.venv/bin/mempalace"
elif command -v mempalace >/dev/null 2>&1; then
  MEMPALACE_BIN="$(command -v mempalace)"
else
  MEMPALACE_BIN=""
fi

if [ -n "${MEMPALACE_BIN_OVERRIDE:-}" ]; then
  MEMPALACE_BIN="$MEMPALACE_BIN_OVERRIDE"
fi

STARTUP_WING="${MEMPALACE_STARTUP_WING:-claude}"
WAKEUP_TEXT=""

if [ -n "$MEMPALACE_BIN" ]; then
  WAKEUP_TEXT="$("$MEMPALACE_BIN" wake-up --wing "$STARTUP_WING" 2>/dev/null || true)"
fi

CONTEXT_FILE="$(mktemp)"
trap 'rm -f "$CONTEXT_FILE"' EXIT

cat > "$CONTEXT_FILE" <<EOF
MemPalace workflow is active for this session.

Use this workflow:
- On startup, treat the wake-up context below as your memory baseline.
- Before answering questions about prior work, decisions, or project history, call mempalace_search or mempalace_kg_query first.
- After substantial work, write a concise mempalace_diary_write entry for the session.
- If you learned or changed a durable fact, use mempalace_kg_add or mempalace_kg_invalidate.
- If a short verbatim snippet matters later, store it with mempalace_add_drawer instead of relying on transcript re-import.

Wake-up context:
$WAKEUP_TEXT
EOF

python3 - <<'PY' "$CONTEXT_FILE"
import json
import pathlib
import sys

context = pathlib.Path(sys.argv[1]).read_text()
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": context,
    }
}, ensure_ascii=False))
PY

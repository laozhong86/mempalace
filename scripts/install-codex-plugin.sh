#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MARKETPLACE_FILE="${HOME}/.agents/plugins/marketplace.json"

if [[ ! -f "$REPO_ROOT/.codex-plugin/plugin.json" ]]; then
  echo "Missing Codex plugin manifest: $REPO_ROOT/.codex-plugin/plugin.json" >&2
  exit 1
fi

python3 - <<'PY' "$MARKETPLACE_FILE" "$REPO_ROOT"
import json
import pathlib
import sys

marketplace_file = pathlib.Path(sys.argv[1])
repo_root = pathlib.Path(sys.argv[2]).resolve()

marketplace_file.parent.mkdir(parents=True, exist_ok=True)

desired_entry = {
    "name": "mempalace",
    "source": {"path": str(repo_root)},
    "description": "Project memory for Codex with MemPalace's local MCP server and startup guidance.",
}

if marketplace_file.exists():
    try:
        data = json.loads(marketplace_file.read_text())
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Invalid marketplace JSON: {marketplace_file}") from exc
else:
    data = {
        "name": "mempalace-dev",
        "owner": {"name": "milla-jovovich"},
        "metadata": {
            "description": "Local development marketplace for the MemPalace Codex plugin."
        },
        "plugins": [],
    }

plugins = data.setdefault("plugins", [])
for index, plugin in enumerate(plugins):
    if plugin.get("name") == "mempalace":
        plugins[index] = desired_entry
        break
else:
    plugins.append(desired_entry)

data.setdefault("name", "mempalace-dev")
data.setdefault("owner", {"name": "milla-jovovich"})
data.setdefault(
    "metadata",
    {"description": "Local development marketplace for the MemPalace Codex plugin."},
)

marketplace_file.write_text(json.dumps(data, indent=2, sort_keys=False) + "\n")
print(marketplace_file)
PY

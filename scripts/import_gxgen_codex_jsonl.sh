#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/import_gxgen_codex_jsonl.sh [--source DIR] [--project-root DIR] [--palace PATH] [--wing NAME] [--days N] [--extract MODE] [--dry-run]

Defaults:
  source      : ~/.codex/archived_sessions
  project-root: /Users/x/Desktop/Project/Gxgen
  palace      : ~/.mempalace/chat-only-script.palace
  wing        : gxgen
  days        : 30
  extract     : exchange

The script filters recent Codex archived sessions by cwd, mirrors the matching
JSONL files into a stable local cache, then mines them into a single project
wing with source metadata attached.
EOF
}

source_dir="${MEMPALACE_SOURCE_DIR:-$HOME/.codex/archived_sessions}"
project_root="${MEMPALACE_PROJECT_ROOT:-/Users/x/Desktop/Project/Gxgen}"
palace_path="${MEMPALACE_PALACE_PATH:-$HOME/.mempalace/chat-only-script.palace}"
wing="${MEMPALACE_WING:-gxgen}"
days="${MEMPALACE_DAYS:-30}"
extract_mode="${MEMPALACE_EXTRACT_MODE:-exchange}"
dry_run="${MEMPALACE_DRY_RUN:-0}"
project_name="${MEMPALACE_PROJECT_NAME:-gxgen}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      source_dir="$2"
      shift 2
      ;;
    --project-root)
      project_root="$2"
      shift 2
      ;;
    --palace)
      palace_path="$2"
      shift 2
      ;;
    --wing)
      wing="$2"
      shift 2
      ;;
    --days)
      days="$2"
      shift 2
      ;;
    --extract)
      extract_mode="$2"
      shift 2
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -x "$repo_root/.venv/bin/python" ]]; then
  py_bin="$repo_root/.venv/bin/python"
elif command -v python3 >/dev/null 2>&1; then
  py_bin="$(command -v python3)"
else
  echo "python3 not found. Run the repo install first." >&2
  exit 1
fi

if [[ ! -d "$source_dir" ]]; then
  echo "Source directory not found: $source_dir" >&2
  exit 1
fi

mirror_root="${MEMPALACE_MIRROR_ROOT:-$HOME/.mempalace/cache/import-mirrors}"
mirror_dir="$mirror_root/project-$project_name/codex-jsonl/recent-$days-days"
mkdir -p "$mirror_dir"

"$py_bin" - <<'PY' "$source_dir" "$project_root" "$mirror_dir" "$days"
from datetime import datetime, timedelta
from pathlib import Path
import json
import shutil
import sys

source_dir = Path(sys.argv[1]).expanduser().resolve()
project_root = str(Path(sys.argv[2]).expanduser().resolve())
mirror_dir = Path(sys.argv[3]).expanduser().resolve()
days = int(sys.argv[4])
cutoff = datetime.now() - timedelta(days=days)

selected = {}
for path in sorted(source_dir.glob("rollout-*.jsonl")):
    try:
        timestamp = path.stem.split("-", 1)[1][:19]
        dt = datetime.strptime(timestamp, "%Y-%m-%dT%H-%M-%S")
    except Exception:
        continue
    if dt < cutoff:
        continue

    try:
        with path.open() as handle:
            first = json.loads(handle.readline())
    except Exception:
        continue

    if first.get("type") != "session_meta":
        continue
    if first.get("payload", {}).get("cwd") != project_root:
        continue

    destination = mirror_dir / path.name
    shutil.copy2(path, destination)
    selected[path.name] = destination

for existing in sorted(mirror_dir.glob("*.jsonl")):
    if existing.name not in selected:
        existing.unlink()

print(len(selected))
for name in list(sorted(selected))[:20]:
    print(name)
PY

if [[ "$dry_run" == "1" ]]; then
  echo "Filtered Gxgen Codex JSONL files copied to: $mirror_dir"
  find "$mirror_dir" -type f | sort
fi

"$py_bin" - <<'PY' "$mirror_dir" "$palace_path" "$wing" "$extract_mode" "$dry_run" "$project_name" "$project_root"
import sys
from mempalace.convo_miner import mine_convos

mirror_dir, palace_path, wing, extract_mode, dry_run, project_name, project_root = sys.argv[1:]

mine_convos(
    convo_dir=mirror_dir,
    palace_path=palace_path,
    wing=wing,
    extract_mode=extract_mode,
    dry_run=dry_run == "1",
    metadata_overrides={
        "project": project_name,
        "source_system": "codex",
        "cwd": project_root,
    },
)
PY

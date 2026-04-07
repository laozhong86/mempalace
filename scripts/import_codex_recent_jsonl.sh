#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/import_codex_recent_jsonl.sh [--source DIR] [--palace PATH] [--wing NAME] [--days N] [--extract MODE] [--dry-run]

Defaults:
  source : ~/.codex/archived_sessions
  palace : ~/.mempalace/chat-only-script.palace
  wing   : codex
  days   : 30
  extract: exchange

The script copies only recent Codex archived session *.jsonl files into a stable
local mirror, then runs MemPalace conversation mining against that filtered set.
EOF
}

source_dir="${MEMPALACE_SOURCE_DIR:-$HOME/.codex/archived_sessions}"
palace_path="${MEMPALACE_PALACE_PATH:-$HOME/.mempalace/chat-only-script.palace}"
wing="${MEMPALACE_WING:-codex}"
days="${MEMPALACE_DAYS:-30}"
extract_mode="${MEMPALACE_EXTRACT_MODE:-exchange}"
dry_run="${MEMPALACE_DRY_RUN:-0}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      source_dir="$2"
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
if [[ -x "$repo_root/.venv/bin/mempalace" ]]; then
  mempalace_bin="$repo_root/.venv/bin/mempalace"
elif command -v mempalace >/dev/null 2>&1; then
  mempalace_bin="$(command -v mempalace)"
else
  echo "mempalace binary not found. Run the repo install first." >&2
  exit 1
fi

if [[ ! -d "$source_dir" ]]; then
  echo "Source directory not found: $source_dir" >&2
  exit 1
fi

source_hash="$(printf '%s|%s' "$source_dir" "$days" | shasum -a 256 | awk '{print substr($1,1,16)}')"
mirror_root="${MEMPALACE_MIRROR_ROOT:-$HOME/.mempalace/cache/import-mirrors}"
mirror_dir="$mirror_root/codex-jsonl/$source_hash"
mkdir -p "$mirror_dir"

python3 - <<'PY' "$source_dir" "$mirror_dir" "$days"
from datetime import datetime, timedelta
from pathlib import Path
import shutil
import sys

source = Path(sys.argv[1]).expanduser().resolve()
mirror = Path(sys.argv[2]).expanduser().resolve()
days = int(sys.argv[3])
cutoff = datetime.now() - timedelta(days=days)

selected = {}
for path in sorted(source.glob("*.jsonl")):
    name = path.name
    if not name.startswith("rollout-"):
        continue
    stem = name[:-6]
    try:
        timestamp = stem.split("-", 1)[1][:19]
        dt = datetime.strptime(timestamp, "%Y-%m-%dT%H-%M-%S")
    except Exception:
        continue
    if dt >= cutoff:
        destination = mirror / name
        shutil.copy2(path, destination)
        selected[destination.name] = destination

for existing in mirror.glob("*.jsonl"):
    if existing.name not in selected:
        existing.unlink()

print(len(selected))
for name in list(sorted(selected))[:20]:
    print(name)
PY

if [[ "$dry_run" == "1" ]]; then
  echo "Filtered recent Codex JSONL files copied to: $mirror_dir"
  find "$mirror_dir" -type f | sort
  "$mempalace_bin" --palace "$palace_path" mine "$mirror_dir" --mode convos --wing "$wing" --extract "$extract_mode" --dry-run
  exit 0
fi

"$mempalace_bin" --palace "$palace_path" mine "$mirror_dir" --mode convos --wing "$wing" --extract "$extract_mode"

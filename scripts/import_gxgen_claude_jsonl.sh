#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/import_gxgen_claude_jsonl.sh [--source-root DIR] [--palace PATH] [--wing NAME] [--extract MODE] [--dry-run]

Defaults:
  source-root: ~/.claude/projects
  palace     : ~/.mempalace/chat-only-script.palace
  wing       : gxgen
  extract    : exchange

The script finds Gxgen-related Claude project directories, mirrors only top-level
session *.jsonl files into a stable local cache, then mines them into a single
project wing with source metadata attached.
EOF
}

source_root="${MEMPALACE_SOURCE_ROOT:-$HOME/.claude/projects}"
palace_path="${MEMPALACE_PALACE_PATH:-$HOME/.mempalace/chat-only-script.palace}"
wing="${MEMPALACE_WING:-gxgen}"
extract_mode="${MEMPALACE_EXTRACT_MODE:-exchange}"
dry_run="${MEMPALACE_DRY_RUN:-0}"
project_name="${MEMPALACE_PROJECT_NAME:-gxgen}"
project_pattern="${MEMPALACE_PROJECT_PATTERN:-*Gxgen*}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-root)
      source_root="$2"
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

if [[ ! -d "$source_root" ]]; then
  echo "Source root not found: $source_root" >&2
  exit 1
fi

mirror_root="${MEMPALACE_MIRROR_ROOT:-$HOME/.mempalace/cache/import-mirrors}"
mirror_dir="$mirror_root/project-$project_name/claude-jsonl"
mkdir -p "$mirror_dir"

"$py_bin" - <<'PY' "$source_root" "$project_pattern" "$mirror_dir"
from pathlib import Path
import shutil
import sys

source_root = Path(sys.argv[1]).expanduser().resolve()
project_pattern = sys.argv[2]
mirror_dir = Path(sys.argv[3]).expanduser().resolve()

selected = {}
for project_dir in sorted(source_root.glob(project_pattern)):
    if not project_dir.is_dir():
        continue
    # Keep only the primary session transcript for each Claude project/worktree.
    # Subagent transcripts add a lot of noisy intermediate reasoning.
    for path in sorted(project_dir.glob("*.jsonl")):
        rel = Path(project_dir.name) / path.relative_to(project_dir)
        destination = mirror_dir / rel
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, destination)
        selected[rel.as_posix()] = destination

for existing in sorted(mirror_dir.rglob("*.jsonl")):
    rel = existing.relative_to(mirror_dir).as_posix()
    if rel not in selected:
        existing.unlink()

for existing_dir in sorted(mirror_dir.rglob("*"), reverse=True):
    if existing_dir.is_dir():
        try:
            existing_dir.rmdir()
        except OSError:
            pass

print(len(selected))
for rel in list(sorted(selected))[:20]:
    print(rel)
PY

if [[ "$dry_run" == "1" ]]; then
  echo "Filtered Gxgen Claude JSONL files copied to: $mirror_dir"
  find "$mirror_dir" -type f | sort
fi

"$py_bin" - <<'PY' "$mirror_dir" "$palace_path" "$wing" "$extract_mode" "$dry_run" "$project_name"
import sys
from mempalace.convo_miner import mine_convos

mirror_dir, palace_path, wing, extract_mode, dry_run, project_name = sys.argv[1:]

mine_convos(
    convo_dir=mirror_dir,
    palace_path=palace_path,
    wing=wing,
    extract_mode=extract_mode,
    dry_run=dry_run == "1",
    metadata_overrides={
        "project": project_name,
        "source_system": "claude",
    },
)
PY

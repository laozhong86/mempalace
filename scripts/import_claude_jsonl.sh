#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/import_claude_jsonl.sh [--source DIR] [--palace PATH] [--wing NAME] [--extract MODE] [--dry-run]

Defaults:
  source : ~/.claude/projects/-Users-x--claude
  palace : ~/.mempalace/chat-only.palace
  wing   : claude
  extract: exchange

The script copies only *.jsonl files into a stable local mirror, then runs
MemPalace conversation mining against that filtered set.
EOF
}

source_dir="${MEMPALACE_SOURCE_DIR:-$HOME/.claude/projects/-Users-x--claude}"
palace_path="${MEMPALACE_PALACE_PATH:-$HOME/.mempalace/chat-only.palace}"
wing="${MEMPALACE_WING:-claude}"
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

source_hash="$(printf '%s' "$source_dir" | shasum -a 256 | awk '{print substr($1,1,16)}')"
mirror_root="${MEMPALACE_MIRROR_ROOT:-$HOME/.mempalace/cache/import-mirrors}"
mirror_dir="$mirror_root/claude-jsonl/$source_hash"
mkdir -p "$mirror_dir"

rsync -a --prune-empty-dirs \
  --include='*/' \
  --include='*.jsonl' \
  --exclude='*' \
  "$source_dir"/ \
  "$mirror_dir"/

if [[ "$dry_run" == "1" ]]; then
  echo "Filtered JSONL files copied to: $mirror_dir"
  find "$mirror_dir" -type f | sort
  "$mempalace_bin" --palace "$palace_path" mine "$mirror_dir" --mode convos --wing "$wing" --extract "$extract_mode" --dry-run
  exit 0
fi

"$mempalace_bin" --palace "$palace_path" mine "$mirror_dir" --mode convos --wing "$wing" --extract "$extract_mode"

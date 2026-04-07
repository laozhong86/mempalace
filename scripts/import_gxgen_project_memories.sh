#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/import_gxgen_project_memories.sh [--palace PATH] [--wing NAME] [--days N] [--extract MODE] [--dry-run]

Defaults:
  palace : ~/.mempalace/chat-only-script.palace
  wing   : gxgen
  days   : 30
  extract: exchange

Runs both the Gxgen Claude import and the recent Gxgen Codex import into the
same project wing. Source system is stored in metadata.
EOF
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
palace_path="${MEMPALACE_PALACE_PATH:-$HOME/.mempalace/chat-only-script.palace}"
wing="${MEMPALACE_WING:-gxgen}"
days="${MEMPALACE_DAYS:-30}"
extract_mode="${MEMPALACE_EXTRACT_MODE:-exchange}"
dry_run="${MEMPALACE_DRY_RUN:-0}"

while [[ $# -gt 0 ]]; do
  case "$1" in
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

"$repo_root/scripts/import_gxgen_claude_jsonl.sh" \
  --palace "$palace_path" \
  --wing "$wing" \
  --extract "$extract_mode" \
  $([[ "$dry_run" == "1" ]] && printf '%s' "--dry-run")

"$repo_root/scripts/import_gxgen_codex_jsonl.sh" \
  --palace "$palace_path" \
  --wing "$wing" \
  --days "$days" \
  --extract "$extract_mode" \
  $([[ "$dry_run" == "1" ]] && printf '%s' "--dry-run")

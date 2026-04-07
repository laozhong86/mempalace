#!/usr/bin/env bash

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PLUGIN_DATA="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugins/data/mempalace}"
RUNTIME_DIR="$PLUGIN_DATA/runtime"
CURRENT_DIR="$RUNTIME_DIR/current"
RELEASES_DIR="$RUNTIME_DIR/releases"
LOG_DIR="$PLUGIN_DATA/logs"
LOCK_FILE="$RUNTIME_DIR/bootstrap.lock"

resolve_default() {
  case "$1" in
    palace_path) printf '%s\n' "$HOME/.mempalace/palace" ;;
    startup_wing) printf '%s\n' "claude" ;;
    save_interval) printf '%s\n' "15" ;;
    *) return 1 ;;
  esac
}

expand_tilde() {
  case "$1" in
    "~") printf '%s\n' "$HOME" ;;
    "~/"*) printf '%s\n' "${1/#\~/$HOME}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

export MEMPALACE_PALACE_PATH="$(expand_tilde "${CLAUDE_PLUGIN_OPTION_PALACE_PATH:-$(resolve_default palace_path)}")"
export MEMPALACE_STARTUP_WING="${CLAUDE_PLUGIN_OPTION_STARTUP_WING:-$(resolve_default startup_wing)}"
export MEMPALACE_SAVE_INTERVAL="${CLAUDE_PLUGIN_OPTION_SAVE_INTERVAL:-$(resolve_default save_interval)}"
export MEMPALACE_STATE_DIR="${MEMPALACE_STATE_DIR:-$PLUGIN_DATA/hook_state}"

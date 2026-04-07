#!/usr/bin/env bash
set -euo pipefail

plugin_runtime_resolve_root() {
  if [[ -n "${PLUGIN_ROOT:-}" ]]; then
    printf '%s\n' "$PLUGIN_ROOT"
    return 0
  fi

  if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    printf '%s\n' "$CLAUDE_PLUGIN_ROOT"
    return 0
  fi

  if [[ -n "${CODEX_PLUGIN_ROOT:-}" ]]; then
    printf '%s\n' "$CODEX_PLUGIN_ROOT"
    return 0
  fi

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  (cd "$script_dir/.." && pwd)
}

plugin_runtime_resolve_data_dir() {
  if [[ -n "${PLUGIN_DATA:-}" ]]; then
    printf '%s\n' "$PLUGIN_DATA"
    return 0
  fi

  if [[ -n "${CLAUDE_PLUGIN_DATA:-}" ]]; then
    printf '%s\n' "$CLAUDE_PLUGIN_DATA"
    return 0
  fi

  if [[ -n "${CODEX_PLUGIN_DATA:-}" ]]; then
    printf '%s\n' "$CODEX_PLUGIN_DATA"
    return 0
  fi

  printf '%s\n' "$HOME/.mempalace/plugin-data"
}

plugin_runtime_resolve_manifest_path() {
  local root
  root="$(plugin_runtime_resolve_root)"

  if [[ -f "$root/.codex-plugin/plugin.json" ]]; then
    printf '%s\n' "$root/.codex-plugin/plugin.json"
    return 0
  fi

  if [[ -f "$root/.claude-plugin/plugin.json" ]]; then
    printf '%s\n' "$root/.claude-plugin/plugin.json"
    return 0
  fi

  printf '%s\n' "$root/.codex-plugin/plugin.json"
}

plugin_runtime_first_set() {
  local name value
  for name in "$@"; do
    value="${!name:-}"
    if [[ -n "$value" ]]; then
      printf '%s\n' "$value"
      return 0
    fi
  done

  return 1
}

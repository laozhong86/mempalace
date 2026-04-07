#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/plugin-env.sh"

exec "$SCRIPT_DIR/../hooks/mempal_precompact_hook.sh"

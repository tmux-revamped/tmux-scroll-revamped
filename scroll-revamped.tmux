#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

chmod +x "${CURRENT_DIR}/src/scroll.sh" 2>/dev/null || true

# shellcheck source=/dev/null
source "${CURRENT_DIR}/src/lib/scroll/routing.sh"

scroll_main

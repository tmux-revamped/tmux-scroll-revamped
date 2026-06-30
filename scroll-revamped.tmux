#!/usr/bin/env bash
#
# scroll-revamped.tmux: TPM entry point.
#
# Sources the routing library and applies the wheel bindings. Every routing
# decision lives in src/lib/scroll/routing.sh and is emitted through a single applier
# seam, so the full binding set is unit tested with a dry-run applier that never
# touches a live tmux. On tmux 3.1+ the wheel rule stays a native, fork-free format
# match over #{alternate_on} and #{mouse_any_flag}; older tmux degrades gracefully.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

chmod +x "${CURRENT_DIR}/src/scroll.sh" 2>/dev/null || true

# shellcheck source=/dev/null
source "${CURRENT_DIR}/src/lib/scroll/routing.sh"

scroll_main

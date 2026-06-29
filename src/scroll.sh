#!/usr/bin/env bash
#
# scroll.sh: command dispatcher for tmux-scroll-revamped.
#
# Usage: scroll.sh check <alternate> <mouse> | speed
#
# check is the fallback used by older tmux without #{||:} support: exit 0 when the
# foreground app should receive the wheel directly, exit 1 to enter copy-mode. The
# alternate flag ("1" when the pane is on the alternate screen) and the mouse flag
# ("1" when the app has turned on mouse reporting) each force passthrough so a
# full-screen or mouse-aware app owns the wheel. speed echoes the configured
# copy-mode throttle.

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/tmux/tmux-ops.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/scroll/scroll.sh"

main() {
  case "${1:-}" in
    check)   scroll_is_passthrough "${2:-}" "${3:-}" ;;
    speed)   scroll_valid_speed "$(get_tmux_option "@scroll_revamped_speed" "")" ;;
    *)       return 0 ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

#!/usr/bin/env bash

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/tmux/tmux-ops.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/scroll/scroll.sh"

scroll_check() {
  local key cached_key cached_val decision
  key="$(scroll_cache_key "${1:-}" "${2:-}" "${3:-}" "${4:-}")"
  cached_key="$(get_tmux_option "@scroll_revamped_cache_key" "")"
  cached_val="$(get_tmux_option "@scroll_revamped_cache_val" "")"
  if [[ "${key}" == "${cached_key}" ]] && { [[ "${cached_val}" == "0" ]] || [[ "${cached_val}" == "1" ]]; }; then
    return "${cached_val}"
  fi
  if scroll_decide "${1:-}" "${2:-}" "${3:-}"; then
    decision=0
  else
    decision=1
  fi
  set_tmux_option "@scroll_revamped_cache_key" "${key}"
  set_tmux_option "@scroll_revamped_cache_val" "${decision}"
  return "${decision}"
}

main() {
  case "${1:-}" in
    check)   scroll_check "${2:-}" "${3:-}" "${4:-}" "${5:-}" ;;
    speed)   scroll_valid_speed "$(get_tmux_option "@scroll_revamped_speed" "")" ;;
    *)       return 0 ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

#!/usr/bin/env bash

[[ -n "${_SCROLL_REVAMPED_LOADED:-}" ]] && return 0
_SCROLL_REVAMPED_LOADED=1

scroll_is_passthrough() {
  local alternate="${1:-}" mouse="${2:-}"
  [[ "${alternate}" == "1" ]] && return 0
  [[ "${mouse}" == "1" ]] && return 0
  return 1
}

scroll_decide() {
  scroll_is_passthrough "${1:-}" "${2:-}" && return 0
  [[ "${3:-}" == "0" ]] && return 0
  return 1
}

scroll_cache_key() {
  printf '%s|%s|%s|%s' "${4:-}" "${1:-}" "${2:-}" "${3:-}"
}

scroll_valid_speed() {
  [[ "${1}" =~ ^[1-9][0-9]*$ ]] && printf '%s' "${1}"
}

export -f scroll_is_passthrough
export -f scroll_decide
export -f scroll_cache_key
export -f scroll_valid_speed

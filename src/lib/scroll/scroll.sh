#!/usr/bin/env bash
#
# scroll.sh: pure helpers for tmux-scroll-revamped.
#
# How the wheel behaves is decided by two tmux formats, read without naming any
# app: a pane on the alternate screen is a full-screen app that owns the wheel, and
# a pane whose foreground app turned on mouse reporting wants the wheel itself.
# Otherwise the wheel enters copy-mode. The fallback predicate is pure and tested.

[[ -n "${_SCROLL_REVAMPED_LOADED:-}" ]] && return 0
_SCROLL_REVAMPED_LOADED=1

# scroll_is_passthrough ALTERNATE MOUSE -> exit 0 when the foreground app should
# receive the wheel directly, else exit 1. Passes through when ALTERNATE is "1"
# (the pane is on the alternate screen, so a full-screen app owns the wheel) or
# when MOUSE is "1" (the app has turned on mouse reporting, so it wants the wheel
# itself). Both come straight from tmux formats, so a full-screen or mouse-aware
# app is detected without ever being named. Used by the fallback binding on tmux
# without #{||:} support.
scroll_is_passthrough() {
  local alternate="${1:-}" mouse="${2:-}"
  [[ "${alternate}" == "1" ]] && return 0
  [[ "${mouse}" == "1" ]] && return 0
  return 1
}

# scroll_valid_speed VALUE -> VALUE when it is a positive integer, else empty. A
# set speed throttles copy-mode wheel scrolling to that many lines per tick, so
# fast trackpad flicks no longer jump pages at a time.
scroll_valid_speed() {
  [[ "${1}" =~ ^[1-9][0-9]*$ ]] && printf '%s' "${1}"
}

export -f scroll_is_passthrough
export -f scroll_valid_speed

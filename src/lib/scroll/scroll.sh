#!/usr/bin/env bash
#
# scroll.sh: pure helpers for tmux-scroll-revamped.
#
# How the wheel behaves is decided by tmux formats, read without naming any app: a
# pane on the alternate screen is a full-screen app that owns the wheel, and a pane
# whose foreground app turned on mouse reporting wants the wheel itself. A pane with
# no scrollback has nothing to copy-mode into. Otherwise the wheel enters copy-mode.
# These predicates are pure and fixture-tested; the bindings that use them live in
# routing.sh.

[[ -n "${_SCROLL_REVAMPED_LOADED:-}" ]] && return 0
_SCROLL_REVAMPED_LOADED=1

# scroll_is_passthrough ALTERNATE MOUSE -> exit 0 when the foreground app should
# receive the wheel directly, else exit 1. Passes through when ALTERNATE is "1"
# (the pane is on the alternate screen, so a full-screen app owns the wheel) or
# when MOUSE is "1" (the app has turned on mouse reporting, so it wants the wheel
# itself). Both come straight from tmux formats, so a full-screen or mouse-aware
# app is detected without ever being named. Used by the fallback binding on tmux
# without native format operators.
scroll_is_passthrough() {
  local alternate="${1:-}" mouse="${2:-}"
  [[ "${alternate}" == "1" ]] && return 0
  [[ "${mouse}" == "1" ]] && return 0
  return 1
}

# scroll_decide ALTERNATE MOUSE SKIPHIST -> exit 0 when the wheel should pass
# through (alternate screen, mouse reporting, or an empty scrollback when the skip
# heuristic is active), else exit 1 to enter copy-mode. SKIPHIST is "#{history_size}"
# only when the skip-empty heuristic is on, so the literal "0" forces passthrough;
# any other value, including the empty string passed when the heuristic is off,
# leaves the copy-mode path intact.
scroll_decide() {
  scroll_is_passthrough "${1:-}" "${2:-}" && return 0
  [[ "${3:-}" == "0" ]] && return 0
  return 1
}

# scroll_cache_key ALTERNATE MOUSE SKIPHIST PANE -> a stable string identifying a
# routing decision. The pre-native fallback stores the last key and its decision in
# a tmux option, so an unchanged pane skips recomputing the predicate on every
# wheel tick.
scroll_cache_key() {
  printf '%s|%s|%s|%s' "${4:-}" "${1:-}" "${2:-}" "${3:-}"
}

# scroll_valid_speed VALUE -> VALUE when it is a positive integer, else empty. A
# set speed throttles copy-mode wheel scrolling to that many lines per tick, so
# fast trackpad flicks no longer jump pages at a time.
scroll_valid_speed() {
  [[ "${1}" =~ ^[1-9][0-9]*$ ]] && printf '%s' "${1}"
}

export -f scroll_is_passthrough
export -f scroll_decide
export -f scroll_cache_key
export -f scroll_valid_speed

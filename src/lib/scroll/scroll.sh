#!/usr/bin/env bash
#
# scroll.sh: pure helpers for tmux-scroll-revamped.
#
# A pane's foreground command decides how the wheel behaves: pass it straight to
# full-screen apps that scroll themselves (vim, less, htop), otherwise enter
# copy-mode. Both the regex used by the fast tmux-native binding and the
# membership check used by the older-tmux fallback are pure and fixture-tested.

[[ -n "${_SCROLL_REVAMPED_LOADED:-}" ]] && return 0
_SCROLL_REVAMPED_LOADED=1

# scroll_build_pattern APPS -> an anchored extended-regex alternation of the
# space or comma separated APPS, for use in a tmux #{m/r:...} match. Empty input
# yields a pattern that matches nothing.
scroll_build_pattern() {
  local alt
  alt="$(printf '%s' "${1}" | tr ',[:space:]' '\n' | awk 'NF && !seen[$0]++{a=a (a?"|":"") $0} END{print a}')"
  [[ -z "${alt}" ]] && { printf '%s' '$^'; return 0; }
  printf '^(%s)$' "${alt}"
}

# scroll_is_passthrough APP APPS -> exit 0 when APP is one of the space or comma
# separated APPS, else exit 1. Used by the fallback binding on tmux without
# regex match support.
scroll_is_passthrough() {
  local app="${1}" a
  while IFS= read -r a; do
    [[ -n "${a}" && "${a}" == "${app}" ]] && return 0
  done <<< "$(printf '%s' "${2}" | tr ',[:space:]' '\n')"
  return 1
}

export -f scroll_build_pattern
export -f scroll_is_passthrough

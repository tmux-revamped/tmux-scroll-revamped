#!/usr/bin/env bash
#
# scroll-revamped.tmux: TPM entry point.
#
# Binds the mouse wheel so a full-screen app (vim, less, htop) or any app that has
# turned on mouse reporting gets the wheel directly, while everything else enters
# copy-mode. A pane on the alternate screen is a full-screen app by definition, and
# a pane whose app requested the mouse wants the wheel itself, so both are detected
# without naming any app. On tmux 3.1+ the routing is a native format match over
# #{alternate_on} and #{mouse_any_flag}, so there is no per-event fork; older tmux
# falls back to a check command.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCROLL_CMD="${CURRENT_DIR}/src/scroll.sh"

chmod +x "${SCROLL_CMD}" 2>/dev/null || true

get_opt() {
  local v
  v=$(tmux show-option -gqv "${1}")
  echo "${v:-${2}}"
}

if [[ "$(get_opt "@scroll_revamped_mouse" "on")" == "on" ]]; then
  tmux set-option -g mouse on
fi

ver="$(tmux -V | sed -E 's/^tmux ([0-9]+\.[0-9]+).*/\1/')"
ge() { [[ "$(printf '%s\n%s\n' "${2}" "${1}" | sort -V | head -n1)" == "${2}" ]]; }

# Alternate-screen passthrough: a pane on the alternate screen is a full-screen
# app, so it owns the wheel. On by default; set off to route purely by app list.
alt_on="$(get_opt "@scroll_revamped_passthrough_alternate" "on")"

# Mouse-reporting passthrough: a pane whose foreground app has turned on mouse
# tracking wants the wheel itself, whatever its name. This is what lets an unlisted
# TUI scroll without ever being added to the app list. On by default; set off to
# ignore the app's mouse mode. #{mouse_any_flag} exists on every tmux TPM supports.
mouse_on="$(get_opt "@scroll_revamped_passthrough_mouse" "on")"

if ge "${ver}" "3.1"; then
  match="#{pane_in_mode}"
  [[ "${alt_on}" == "on" ]] && match="#{||:#{alternate_on},${match}}"
  [[ "${mouse_on}" == "on" ]] && match="#{||:#{mouse_any_flag},${match}}"
  cond="#{?${match},1,0}"
  tmux bind-key -n WheelUpPane if-shell -F "${cond}" "send-keys -M" "copy-mode -e; send-keys -M"
else
  alt_flag="0"
  [[ "${alt_on}" == "on" ]] && alt_flag="#{alternate_on}"
  mouse_flag="0"
  [[ "${mouse_on}" == "on" ]] && mouse_flag="#{mouse_any_flag}"
  tmux bind-key -n WheelUpPane if-shell "${SCROLL_CMD} check '${alt_flag}' '${mouse_flag}'" "send-keys -M" "copy-mode -e; send-keys -M"
fi

tmux bind-key -n WheelDownPane send-keys -M

# Optional throttle: cap copy-mode wheel scrolling to a fixed number of lines per
# tick so a fast trackpad flick no longer jumps whole pages. send-keys -X -N is
# available from tmux 2.4. Unset or non-numeric leaves tmux's default behavior.
speed="$("${SCROLL_CMD}" speed)"
if [[ -n "${speed}" ]] && ge "${ver}" "2.4"; then
  for table in copy-mode copy-mode-vi; do
    tmux bind-key -T "${table}" WheelUpPane send-keys -X -N "${speed}" scroll-up
    tmux bind-key -T "${table}" WheelDownPane send-keys -X -N "${speed}" scroll-down
  done
fi

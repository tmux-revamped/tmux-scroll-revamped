#!/usr/bin/env bash
#
# scroll-revamped.tmux: TPM entry point.
#
# Binds the mouse wheel so full-screen apps (vim, less, htop) get the wheel
# directly while everything else enters copy-mode. On tmux 3.1+ the routing is a
# native regex match over #{pane_current_command}, so there is no per-event fork;
# older tmux falls back to a check command.

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

if ge "${ver}" "3.1"; then
  pattern="$("${SCROLL_CMD}" pattern)"
  cond="#{?#{||:#{pane_in_mode},#{m/r:${pattern},#{pane_current_command}}},1,0}"
  tmux bind-key -n WheelUpPane if-shell -F "${cond}" "send-keys -M" "copy-mode -e; send-keys -M"
else
  tmux bind-key -n WheelUpPane if-shell "${SCROLL_CMD} check '#{pane_current_command}'" "send-keys -M" "copy-mode -e; send-keys -M"
fi

tmux bind-key -n WheelDownPane send-keys -M

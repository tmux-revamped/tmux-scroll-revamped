#!/usr/bin/env bash
#
# routing.sh: wheel-binding builder for tmux-scroll-revamped.
#
# Every tmux command is emitted through scroll_emit so the whole binding set can be
# captured and asserted by a dry-run applier in the tests without ever touching a
# live tmux. Production replaces scroll_emit with a thin "tmux $@" call. The builders
# are version-gated and read only @scroll_revamped_* options. On tmux 3.1+ the wheel
# decision stays a native, fork-free format match (#{||:} of #{alternate_on} and
# #{mouse_any_flag}); 2.0 to 3.0 keep it fork-free with nested #{?} under if-shell -F;
# only 1.9 falls back to a per-event check command, and that decision is cached.

[[ -n "${_SCROLL_REVAMPED_ROUTING_LOADED:-}" ]] && return 0
_SCROLL_REVAMPED_ROUTING_LOADED=1

ROUTING_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SCROLL_REVAMPED_CMD="${ROUTING_ROOT}/src/scroll.sh"

# shellcheck source=/dev/null
source "${ROUTING_ROOT}/src/lib/tmux/tmux-ops.sh"
# shellcheck source=/dev/null
source "${ROUTING_ROOT}/src/lib/scroll/scroll.sh"
# shellcheck source=/dev/null
source "${ROUTING_ROOT}/src/lib/utils/platform.sh"
# shellcheck source=/dev/null
source "${ROUTING_ROOT}/src/lib/utils/has-command.sh"

# scroll_emit ARGS... -> run a tmux command. Tests override this to record the
# command string instead of executing it, which is how every branch is asserted.
scroll_emit() {
  tmux "$@"
}

# scroll_tmux_version -> the running tmux as "MAJOR.MINOR". Overridden in tests to
# pin a version so every gate is exercised deterministically.
scroll_tmux_version() {
  tmux -V 2>/dev/null | sed -E 's/^tmux ([0-9]+\.[0-9]+).*/\1/'
}

# scroll_opt NAME DEFAULT -> the value of @scroll_revamped_NAME.
scroll_opt() {
  get_tmux_option "@scroll_revamped_${1}" "${2}"
}

# scroll_ge VER MIN -> exit 0 when VER is at least MIN.
scroll_ge() {
  [[ "$(printf '%s\n%s\n' "${2}" "${1}" | sort -V | head -n1)" == "${2}" ]]
}

# scroll_or VER A B -> a tmux format that is true when A or B is true. Native
# #{||:} on 3.1+, nested #{?} below so the same expressivity reaches 1.9.
scroll_or() {
  if scroll_ge "${1}" "3.1"; then
    printf '#{||:%s,%s}' "${2}" "${3}"
  else
    printf '#{?%s,1,%s}' "${2}" "${3}"
  fi
}

# scroll_and VER A B -> a tmux format that is true when A and B are true.
scroll_and() {
  if scroll_ge "${1}" "3.1"; then
    printf '#{&&:%s,%s}' "${2}" "${3}"
  else
    printf '#{?%s,%s,0}' "${2}" "${3}"
  fi
}

# scroll_not COND -> a tmux format that negates COND.
scroll_not() {
  printf '#{?%s,0,1}' "${1}"
}

# scroll_passthrough_condition VER ALT MOUSE SKIP -> the format, true when the wheel
# should reach the app or stay in copy-mode rather than entering it. pane_in_mode is
# always included so a wheel inside copy-mode is handed to the copy-mode table.
scroll_passthrough_condition() {
  local ver="${1}" alt="${2}" mouse="${3}" skip="${4}"
  local cond="#{pane_in_mode}"
  [[ "${skip}" == "on" ]] && cond="$(scroll_or "${ver}" "#{==:#{history_size},0}" "${cond}")"
  [[ "${mouse}" == "on" ]] && cond="$(scroll_or "${ver}" "#{mouse_any_flag}" "${cond}")"
  [[ "${alt}" == "on" ]] && cond="$(scroll_or "${ver}" "#{alternate_on}" "${cond}")"
  printf '%s' "${cond}"
}

# scroll_passthrough_action VER ALTKEYS COUNT DIR -> the command run when the wheel
# passes through. Default is "send-keys -M" so a mouse-aware app gets the raw event.
# With ALTKEYS set to arrow or page, an alternate-screen pane that has NOT turned on
# mouse reporting (less, man, vi with mouse off, where the wheel is otherwise dead)
# receives COUNT arrow or page keys instead.
scroll_passthrough_action() {
  local ver="${1}" altkeys="${2}" count="${3}" dir="${4}"
  local mouse_action="send-keys -M"
  if { [[ "${altkeys}" == "arrow" ]] || [[ "${altkeys}" == "page" ]]; } && scroll_ge "${ver}" "2.0"; then
    local key altcond keys n=0 reps=1
    if [[ "${altkeys}" == "arrow" ]]; then
      [[ "${dir}" == "up" ]] && key="Up" || key="Down"
      reps="${count:-1}"
    else
      [[ "${dir}" == "up" ]] && key="PageUp" || key="PageDown"
    fi
    keys="${key}"
    while [[ "${n}" -lt $(( reps - 1 )) ]]; do
      keys="${keys} ${key}"
      n=$(( n + 1 ))
    done
    altcond="$(scroll_and "${ver}" "#{alternate_on}" "$(scroll_not "#{mouse_any_flag}")")"
    printf "if-shell -F '#{?%s,1,0}' 'send-keys %s' '%s'" "${altcond}" "${keys}" "${mouse_action}"
  else
    printf '%s' "${mouse_action}"
  fi
}

# scroll_clipboard_command -> the shell command that copies stdin to the system
# clipboard, or empty when none is available. Used by the drag-select copy binding.
scroll_clipboard_command() {
  if is_macos && has_command pbcopy; then
    printf 'pbcopy'
  elif has_command wl-copy; then
    printf 'wl-copy'
  elif has_command xclip; then
    printf 'xclip -selection clipboard -in'
  elif has_command xsel; then
    printf 'xsel --clipboard --input'
  fi
}

# scroll_build_wheel VER -> emit the root-table WheelUpPane and WheelDownPane
# bindings. tmux 2.0+ routes with a fork-free if-shell -F; 1.9 forks a cached check.
scroll_build_wheel() {
  local ver="${1}"
  local alt mouse skip altkeys selectpane count prefix=""
  alt="$(scroll_opt passthrough_alternate on)"
  mouse="$(scroll_opt passthrough_mouse on)"
  skip="$(scroll_opt skip_empty off)"
  altkeys="$(scroll_opt alt_keys "")"
  selectpane="$(scroll_opt select_pane off)"
  count="$(scroll_valid_speed "$(scroll_opt speed "")")"
  [[ "${altkeys}" == "arrow" && -z "${count}" ]] && count="3"
  [[ "${selectpane}" == "on" ]] && prefix="select-pane -t = ; "

  local copymode="copy-mode -e ; send-keys -M"

  if scroll_ge "${ver}" "2.0"; then
    local cond up_action down_action up_cmd down_cmd
    cond="#{?$(scroll_passthrough_condition "${ver}" "${alt}" "${mouse}" "${skip}"),1,0}"
    up_action="$(scroll_passthrough_action "${ver}" "${altkeys}" "${count}" up)"
    down_action="$(scroll_passthrough_action "${ver}" "${altkeys}" "${count}" down)"
    up_cmd="$(printf 'if-shell -F "%s" "%s" "%s"' "${cond}" "${up_action}" "${copymode}")"
    scroll_emit bind-key -n WheelUpPane "${prefix}${up_cmd}"
    down_cmd="${prefix}${down_action}"
    scroll_emit bind-key -n WheelDownPane "${down_cmd}"
  else
    local alt_flag="0" mouse_flag="0" hist=""
    [[ "${alt}" == "on" ]] && alt_flag="#{alternate_on}"
    [[ "${mouse}" == "on" ]] && mouse_flag="#{mouse_any_flag}"
    [[ "${skip}" == "on" ]] && hist="#{history_size}"
    local check up_cmd
    check="${SCROLL_REVAMPED_CMD} check '${alt_flag}' '${mouse_flag}' '${hist}' '#{pane_id}'"
    up_cmd="$(printf 'if-shell "%s" "%s" "%s"' "${check}" "send-keys -M" "${copymode}")"
    scroll_emit bind-key -n WheelUpPane "${prefix}${up_cmd}"
    scroll_emit bind-key -n WheelDownPane "${prefix}send-keys -M"
  fi
}

# _scroll_x_command COUNT GRAN DIR -> the send-keys -X command for one copy-mode
# wheel tick at the configured granularity, with the optional line throttle.
_scroll_x_command() {
  local count="${1}" gran="${2}" dir="${3}" verb
  case "${gran}" in
    page)     [[ "${dir}" == "up" ]] && verb="page-up" || verb="page-down" ;;
    halfpage) [[ "${dir}" == "up" ]] && verb="halfpage-up" || verb="halfpage-down" ;;
    *)        [[ "${dir}" == "up" ]] && verb="scroll-up" || verb="scroll-down" ;;
  esac
  if [[ -n "${count}" && "${gran}" == "line" ]]; then
    printf 'send-keys -X -N %s %s' "${count}" "${verb}"
  else
    printf 'send-keys -X %s' "${verb}"
  fi
}

# scroll_build_copymode VER -> emit the copy-mode and copy-mode-vi wheel bindings
# for granularity, throttle, auto-exit at the bottom, the position indicator, and
# drag-select to the system clipboard. All require send-keys -X, so 2.4 is the floor.
scroll_build_copymode() {
  local ver="${1}"
  scroll_ge "${ver}" "2.4" || return 0
  local gran count autoexit indicator dragcopy
  gran="$(scroll_opt granularity line)"
  count="$(scroll_valid_speed "$(scroll_opt speed "")")"
  autoexit="$(scroll_opt auto_exit off)"
  indicator="$(scroll_opt indicator off)"
  dragcopy="$(scroll_opt drag_copy off)"
  [[ "${gran}" =~ ^(line|halfpage|page)$ ]] || gran="line"

  local need=0
  { [[ "${gran}" != "line" ]] || [[ -n "${count}" ]] || [[ "${autoexit}" == "on" ]] \
    || [[ "${indicator}" == "on" ]]; } && need=1

  local show_indicator=0
  [[ "${indicator}" == "on" ]] && scroll_ge "${ver}" "2.9" && show_indicator=1

  local clip=""
  [[ "${dragcopy}" == "on" ]] && clip="$(scroll_clipboard_command)"

  local table up_action down_action indic="display-message -d 700 'scroll #{scroll_position}/#{history_size}'"
  for table in copy-mode copy-mode-vi; do
    if [[ "${need}" -eq 1 ]]; then
      up_action="$(_scroll_x_command "${count}" "${gran}" up)"
      if [[ "${autoexit}" == "on" ]]; then
        down_action="$(printf "if-shell -F '#{?#{==:#{scroll_position},0},1,0}' 'send-keys -X cancel' '%s'" "$(_scroll_x_command "${count}" "${gran}" down)")"
      else
        down_action="$(_scroll_x_command "${count}" "${gran}" down)"
      fi
      if [[ "${show_indicator}" -eq 1 ]]; then
        up_action="${up_action} ; ${indic}"
        down_action="${down_action} ; ${indic}"
      fi
      scroll_emit bind-key -T "${table}" WheelUpPane "${up_action}"
      scroll_emit bind-key -T "${table}" WheelDownPane "${down_action}"
    fi
    if [[ -n "${clip}" ]]; then
      scroll_emit bind-key -T "${table}" MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "${clip}"
    fi
  done
}

# scroll_build_status VER -> when @scroll_revamped_status_wheel is on, the wheel
# over the status line switches windows. WheelUpStatus and WheelDownStatus exist 2.1+.
scroll_build_status() {
  local ver="${1}"
  [[ "$(scroll_opt status_wheel off)" == "on" ]] || return 0
  scroll_ge "${ver}" "2.1" || return 0
  scroll_emit bind-key -n WheelUpStatus previous-window
  scroll_emit bind-key -n WheelDownStatus next-window
}

# scroll_main -> detect the version, manage mouse mode, and apply every binding set.
scroll_main() {
  local ver
  ver="$(scroll_tmux_version)"
  [[ "$(scroll_opt mouse on)" == "on" ]] && scroll_emit set-option -g mouse on
  scroll_build_wheel "${ver}"
  scroll_build_copymode "${ver}"
  scroll_build_status "${ver}"
}

export -f scroll_emit
export -f scroll_tmux_version
export -f scroll_opt
export -f scroll_ge
export -f scroll_or
export -f scroll_and
export -f scroll_not
export -f scroll_passthrough_condition
export -f scroll_passthrough_action
export -f scroll_clipboard_command
export -f scroll_build_wheel
export -f _scroll_x_command
export -f scroll_build_copymode
export -f scroll_build_status
export -f scroll_main

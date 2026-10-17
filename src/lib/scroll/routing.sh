#!/usr/bin/env bash

[[ -n "${_SCROLL_REVAMPED_ROUTING_LOADED:-}" ]] && return 0
_SCROLL_REVAMPED_ROUTING_LOADED=1

ROUTING_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SCROLL_REVAMPED_CMD="${ROUTING_ROOT}/src/scroll.sh"
SCROLL_REVAMPED_MAX_ALT_KEYS=20

# shellcheck source=/dev/null
source "${ROUTING_ROOT}/src/lib/tmux/tmux-ops.sh"
# shellcheck source=/dev/null
source "${ROUTING_ROOT}/src/lib/scroll/scroll.sh"
# shellcheck source=/dev/null
source "${ROUTING_ROOT}/src/lib/utils/platform.sh"
# shellcheck source=/dev/null
source "${ROUTING_ROOT}/src/lib/utils/has-command.sh"

scroll_emit() {
  tmux "$@"
}

scroll_tmux_version() {
  tmux -V 2>/dev/null | sed -E 's/^tmux ([0-9]+\.[0-9]+).*/\1/'
}

scroll_opt() {
  get_tmux_option "@scroll_revamped_${1}" "${2}"
}

scroll_tmux_quoted_path() {
  local word bs='\' bs2='\\' dq='"' bsdq='\"' dollar='$' bsdollar='\$' hash='#' hash2='##'
  printf -v word '%q' "${1}"
  word=${word//"${bs}"/"${bs2}"}
  word=${word//"${dq}"/"${bsdq}"}
  word=${word//"${dollar}"/"${bsdollar}"}
  word=${word//"${hash}"/"${hash2}"}
  printf '%s' "${word}"
}

scroll_version_part() {
  local ver="${1}" major minor
  ver="${ver#"${ver%%[0-9]*}"}"
  major="${ver%%[!0-9]*}"
  minor=""
  [[ "${ver}" == "${major}."* ]] && minor="${ver#"${major}".}"
  minor="${minor%%[!0-9]*}"
  if [[ "${2}" == "major" ]]; then
    printf '%s' "$(( 10#${major:-0} ))"
  else
    printf '%s' "$(( 10#${minor:-0} ))"
  fi
}

scroll_ge() {
  local have_major have_minor need_major need_minor
  [[ -n "${1}" ]] || return 1
  have_major="$(scroll_version_part "${1}" major)"
  have_minor="$(scroll_version_part "${1}" minor)"
  need_major="$(scroll_version_part "${2}" major)"
  need_minor="$(scroll_version_part "${2}" minor)"
  (( have_major > need_major || (have_major == need_major && have_minor >= need_minor) ))
}

scroll_or() {
  if scroll_ge "${1}" "3.1"; then
    printf '#{||:%s,%s}' "${2}" "${3}"
  else
    printf '#{?%s,1,%s}' "${2}" "${3}"
  fi
}

scroll_and() {
  if scroll_ge "${1}" "3.1"; then
    printf '#{&&:%s,%s}' "${2}" "${3}"
  else
    printf '#{?%s,%s,0}' "${2}" "${3}"
  fi
}

scroll_not() {
  printf '#{?%s,0,1}' "${1}"
}

scroll_passthrough_condition() {
  local ver="${1}" alt="${2}" mouse="${3}" skip="${4}"
  local cond="#{pane_in_mode}"
  [[ "${skip}" == "on" ]] && cond="$(scroll_or "${ver}" "#{==:#{history_size},0}" "${cond}")"
  [[ "${mouse}" == "on" ]] && cond="$(scroll_or "${ver}" "#{mouse_any_flag}" "${cond}")"
  [[ "${alt}" == "on" ]] && cond="$(scroll_or "${ver}" "#{alternate_on}" "${cond}")"
  printf '%s' "${cond}"
}

scroll_passthrough_action() {
  local ver="${1}" altkeys="${2}" count="${3}" dir="${4}"
  local mouse_action="send-keys -M"
  if { [[ "${altkeys}" == "arrow" ]] || [[ "${altkeys}" == "page" ]]; } && scroll_ge "${ver}" "2.0"; then
    local key altcond keys n=0 reps=1
    if [[ "${altkeys}" == "arrow" ]]; then
      [[ "${dir}" == "up" ]] && key="Up" || key="Down"
      reps="${count:-1}"
      if [[ "${#reps}" -gt "${#SCROLL_REVAMPED_MAX_ALT_KEYS}" ]] || [[ "${reps}" -gt "${SCROLL_REVAMPED_MAX_ALT_KEYS}" ]]; then
        reps="${SCROLL_REVAMPED_MAX_ALT_KEYS}"
      fi
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
    check="$(scroll_tmux_quoted_path "${SCROLL_REVAMPED_CMD}") check '${alt_flag}' '${mouse_flag}' '${hist}' '#{pane_id}'"
    up_cmd="$(printf 'if-shell "%s" "%s" "%s"' "${check}" "send-keys -M" "${copymode}")"
    scroll_emit bind-key -n WheelUpPane "${prefix}${up_cmd}"
    scroll_emit bind-key -n WheelDownPane "${prefix}send-keys -M"
  fi
}

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
  [[ "${indicator}" == "on" ]] && scroll_ge "${ver}" "3.2" && show_indicator=1

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

scroll_build_status() {
  local ver="${1}"
  [[ "$(scroll_opt status_wheel off)" == "on" ]] || return 0
  scroll_ge "${ver}" "2.1" || return 0
  scroll_emit bind-key -n WheelUpStatus previous-window
  scroll_emit bind-key -n WheelDownStatus next-window
}

scroll_main() {
  local ver
  ver="$(scroll_tmux_version)"
  [[ "$(scroll_opt mouse on)" == "on" ]] && scroll_emit set-option -g mouse on
  if [[ "$(scroll_opt wheel off)" == "on" ]]; then
    scroll_build_wheel "${ver}"
  fi
  scroll_build_copymode "${ver}"
  scroll_build_status "${ver}"
}

export -f scroll_emit
export -f scroll_tmux_version
export -f scroll_opt
export -f scroll_tmux_quoted_path
export -f scroll_version_part
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

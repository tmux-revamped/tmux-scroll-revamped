#!/bin/sh

[ -n "${SCROLL_REVAMPED_SCROLL_LOADED:-}" ] && return 0
SCROLL_REVAMPED_SCROLL_LOADED=1

# shellcheck source=SCRIPTDIR/state.sh
. "${REVAMPED_LIB:?}/state.sh"
# shellcheck source=SCRIPTDIR/platform.sh
. "${REVAMPED_LIB}/platform.sh"
# shellcheck source=SCRIPTDIR/command.sh
. "${REVAMPED_LIB}/command.sh"

scroll_revamped_format() {
  printf '%s\n' "${SCROLL_REVAMPED_SETTINGS}" | awk -F '\t' '{ printf "%s#{@scroll_revamped_%s}", (NR > 1 ? "\t" : ""), $1 }'
}

scroll_revamped_resolve() {
  env | SCROLL_REVAMPED_ROWS="${SCROLL_REVAMPED_SETTINGS}" SCROLL_REVAMPED_LIVE="$1" awk '
    BEGIN {
      count = split(ENVIRON["SCROLL_REVAMPED_ROWS"], rows, "\n")
      split(ENVIRON["SCROLL_REVAMPED_LIVE"], live, "\t")
      for (i = 1; i <= count; i++) {
        split(rows[i], field, "\t")
        name[i] = field[1]
        value[i] = (live[i] != "") ? live[i] : field[2]
        want["SCROLL_REVAMPED_" toupper(field[1])] = i
      }
    }
    {
      at = index($0, "=")
      key = substr($0, 1, at - 1)
      if (key in want) { value[want[key]] = substr($0, at + 1) }
    }
    END { for (i = 1; i <= count; i++) { print name[i] "\t" value[i] } }
  '
}

scroll_revamped_load() {
  scroll_revamped_load_format=$(scroll_revamped_format)
  scroll_revamped_load_live=$(tmux display-message -p "${scroll_revamped_load_format}" 2>/dev/null) || scroll_revamped_load_live=""
  scroll_revamped_load_values=$(scroll_revamped_resolve "${scroll_revamped_load_live}")
  while IFS='	' read -r scroll_revamped_load_name scroll_revamped_load_value; do
    IFS= read -r "SCROLL_REVAMPED_S_${scroll_revamped_load_name}" <<EOF
${scroll_revamped_load_value}
EOF
  done <<EOF
${scroll_revamped_load_values}
EOF
}

scroll_revamped_parse_version() {
  printf '%s\n' "$1" | sed -En 's/^tmux[ -]([a-z]+-)?([0-9]+\.[0-9]+).*/\2/p'
}

scroll_revamped_version_ge() {
  case "$1:$2" in
  *[!0-9.:]* | :* | *:) return 1 ;;
  *) ;;
  esac
  scroll_revamped_version_ge_have="${1%%.*}"
  scroll_revamped_version_ge_want="${2%%.*}"
  [ "${scroll_revamped_version_ge_have}" -gt "${scroll_revamped_version_ge_want}" ] && return 0
  [ "${scroll_revamped_version_ge_have}" -eq "${scroll_revamped_version_ge_want}" ] || return 1
  scroll_revamped_version_ge_have="${1#*.}"
  scroll_revamped_version_ge_want="${2#*.}"
  [ "${scroll_revamped_version_ge_have%%.*}" -ge "${scroll_revamped_version_ge_want%%.*}" ]
}

scroll_revamped_at_least() {
  scroll_revamped_version_ge "${SCROLL_REVAMPED_TMUX}" "$1"
}

scroll_revamped_valid_speed() {
  case "$1" in
  "" | *[!0-9]* | 0*) : ;;
  *) printf '%s' "$1" ;;
  esac
}

scroll_revamped_emit() {
  for scroll_revamped_emit_arg in "$@"; do
    SCROLL_REVAMPED_PLAN="${SCROLL_REVAMPED_PLAN}${scroll_revamped_emit_arg}
"
  done
  SCROLL_REVAMPED_PLAN="${SCROLL_REVAMPED_PLAN}
"
}

scroll_revamped_or() {
  if scroll_revamped_at_least 3.1; then
    printf '#{||:%s,%s}' "$1" "$2"
  else
    printf '#{?%s,1,%s}' "$1" "$2"
  fi
}

scroll_revamped_and() {
  if scroll_revamped_at_least 3.1; then
    printf '#{&&:%s,%s}' "$1" "$2"
  else
    printf '#{?%s,%s,0}' "$1" "$2"
  fi
}

scroll_revamped_condition() {
  scroll_revamped_condition_out='#{pane_in_mode}'
  if [ "${SCROLL_REVAMPED_S_skip_empty}" = on ]; then
    scroll_revamped_condition_out=$(scroll_revamped_or '#{==:#{history_size},0}' "${scroll_revamped_condition_out}")
  fi
  if [ "${SCROLL_REVAMPED_S_passthrough_mouse}" = on ]; then
    scroll_revamped_condition_out=$(scroll_revamped_or '#{mouse_any_flag}' "${scroll_revamped_condition_out}")
  fi
  if [ "${SCROLL_REVAMPED_S_passthrough_alternate}" = on ]; then
    scroll_revamped_condition_out=$(scroll_revamped_or '#{alternate_on}' "${scroll_revamped_condition_out}")
  fi
  printf '%s' "${scroll_revamped_condition_out}"
}

scroll_revamped_reps() {
  case "$1" in
  ??? | ????*) printf '%s' "${SCROLL_REVAMPED_MAX_REPEATS}" ;;
  *)
    if [ "$1" -gt "${SCROLL_REVAMPED_MAX_REPEATS}" ]; then
      printf '%s' "${SCROLL_REVAMPED_MAX_REPEATS}"
    else
      printf '%s' "$1"
    fi
    ;;
  esac
}

scroll_revamped_action() {
  scroll_revamped_action_key=""
  case "${SCROLL_REVAMPED_S_alt_keys}:$1" in
  arrow:up) scroll_revamped_action_key=Up ;;
  arrow:down) scroll_revamped_action_key=Down ;;
  page:up) scroll_revamped_action_key=PageUp ;;
  page:down) scroll_revamped_action_key=PageDown ;;
  *) : ;;
  esac
  if [ -z "${scroll_revamped_action_key}" ] || ! scroll_revamped_at_least 2.0; then
    printf 'send-keys -M'
    return 0
  fi
  scroll_revamped_action_reps=1
  [ "${SCROLL_REVAMPED_S_alt_keys}" != arrow ] || scroll_revamped_action_reps=$(scroll_revamped_reps "${SCROLL_REVAMPED_COUNT:-3}")
  scroll_revamped_action_keys="${scroll_revamped_action_key}"
  while [ "${scroll_revamped_action_reps}" -gt 1 ]; do
    scroll_revamped_action_keys="${scroll_revamped_action_keys} ${scroll_revamped_action_key}"
    scroll_revamped_action_reps=$((scroll_revamped_action_reps - 1))
  done
  scroll_revamped_action_cond=$(scroll_revamped_and '#{alternate_on}' '#{?#{mouse_any_flag},0,1}')
  printf "if-shell -F '#{?%s,1,0}' 'send-keys %s' 'send-keys -M'" "${scroll_revamped_action_cond}" "${scroll_revamped_action_keys}"
}

scroll_revamped_tool() {
  scroll_revamped_tool_quoted=$(printf '%s\n' "${REVAMPED_LIB%/lib}/bin/scroll-revamped" | sed "s/'/'\\\\''/g")
  printf "'%s'\n" "${scroll_revamped_tool_quoted}" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\$/\\$/g' -e 's/#/##/g'
}

scroll_revamped_plan_old_wheel() {
  scroll_revamped_plan_old_wheel_alt=0
  scroll_revamped_plan_old_wheel_mouse=0
  scroll_revamped_plan_old_wheel_hist=""
  [ "${SCROLL_REVAMPED_S_passthrough_alternate}" != on ] || scroll_revamped_plan_old_wheel_alt='#{alternate_on}'
  [ "${SCROLL_REVAMPED_S_passthrough_mouse}" != on ] || scroll_revamped_plan_old_wheel_mouse='#{mouse_any_flag}'
  [ "${SCROLL_REVAMPED_S_skip_empty}" != on ] || scroll_revamped_plan_old_wheel_hist='#{history_size}'
  scroll_revamped_plan_old_wheel_tool=$(scroll_revamped_tool)
  scroll_revamped_plan_old_wheel_check="${scroll_revamped_plan_old_wheel_tool} check '${scroll_revamped_plan_old_wheel_alt}' '${scroll_revamped_plan_old_wheel_mouse}' '${scroll_revamped_plan_old_wheel_hist}' '#{pane_id}'"
  scroll_revamped_plan_old_wheel_up=$(printf 'if-shell "%s" "%s" "%s"' "${scroll_revamped_plan_old_wheel_check}" 'send-keys -M' 'copy-mode -e ; send-keys -M')
  scroll_revamped_emit bind-key -n WheelUpPane "$1${scroll_revamped_plan_old_wheel_up}"
  scroll_revamped_emit bind-key -n WheelDownPane "$1send-keys -M"
}

scroll_revamped_plan_wheel() {
  [ "${SCROLL_REVAMPED_S_wheel}" = on ] || return 0
  scroll_revamped_plan_wheel_prefix=""
  [ "${SCROLL_REVAMPED_S_select_pane}" != on ] || scroll_revamped_plan_wheel_prefix='select-pane -t = ; '
  if ! scroll_revamped_at_least 2.0; then
    scroll_revamped_plan_old_wheel "${scroll_revamped_plan_wheel_prefix}"
    return 0
  fi
  scroll_revamped_plan_wheel_cond=$(scroll_revamped_condition)
  scroll_revamped_plan_wheel_up=$(scroll_revamped_action up)
  scroll_revamped_plan_wheel_down=$(scroll_revamped_action down)
  scroll_revamped_plan_wheel_up=$(printf 'if-shell -F "#{?%s,1,0}" "%s" "copy-mode -e ; %s"' "${scroll_revamped_plan_wheel_cond}" "${scroll_revamped_plan_wheel_up}" "${SCROLL_REVAMPED_FIRST}")
  scroll_revamped_emit bind-key -n WheelUpPane "${scroll_revamped_plan_wheel_prefix}${scroll_revamped_plan_wheel_up}"
  scroll_revamped_emit bind-key -n WheelDownPane "${scroll_revamped_plan_wheel_prefix}${scroll_revamped_plan_wheel_down}"
}

scroll_revamped_smooth_command() {
  scroll_revamped_smooth_command_lines="${SCROLL_REVAMPED_COUNT:-${SCROLL_REVAMPED_STOCK_LINES}}"
  scroll_revamped_smooth_command_steps=$(scroll_revamped_reps "${scroll_revamped_smooth_command_lines}")
  scroll_revamped_smooth_command_each=$((scroll_revamped_smooth_command_lines / scroll_revamped_smooth_command_steps))
  scroll_revamped_smooth_command_first=$((scroll_revamped_smooth_command_each + scroll_revamped_smooth_command_lines % scroll_revamped_smooth_command_steps))
  scroll_revamped_smooth_command_out="send-keys -X -N ${scroll_revamped_smooth_command_first} scroll-$1"
  scroll_revamped_smooth_command_step="send-keys -X -N ${scroll_revamped_smooth_command_each} scroll-$1"
  [ "$1" = up ] || scroll_revamped_smooth_command_step="if-shell -F \"#{pane_in_mode}\" \"${scroll_revamped_smooth_command_step}\""
  while [ "${scroll_revamped_smooth_command_steps}" -gt 1 ]; do
    scroll_revamped_smooth_command_out="${scroll_revamped_smooth_command_out} ; run-shell -d ${SCROLL_REVAMPED_SMOOTH_SECONDS} ; ${scroll_revamped_smooth_command_step}"
    scroll_revamped_smooth_command_steps=$((scroll_revamped_smooth_command_steps - 1))
  done
  printf '%s' "${scroll_revamped_smooth_command_out}"
}

scroll_revamped_x_command() {
  if [ "${SCROLL_REVAMPED_SMOOTHED}" -eq 1 ]; then
    scroll_revamped_smooth_command "$1"
    return 0
  fi
  scroll_revamped_x_command_verb="scroll-$1"
  case "${SCROLL_REVAMPED_S_granularity}" in
  page) scroll_revamped_x_command_verb="page-$1" ;;
  halfpage) scroll_revamped_x_command_verb="halfpage-$1" ;;
  *) : ;;
  esac
  case "${SCROLL_REVAMPED_COUNT}:${SCROLL_REVAMPED_S_granularity}" in
  ?*:line) printf 'send-keys -X -N %s %s' "${SCROLL_REVAMPED_COUNT}" "${scroll_revamped_x_command_verb}" ;;
  *) printf 'send-keys -X %s' "${scroll_revamped_x_command_verb}" ;;
  esac
}

scroll_revamped_clipboard() {
  if revamped_is_macos && revamped_has_command pbcopy; then
    printf 'pbcopy'
  elif revamped_has_command wl-copy; then
    printf 'wl-copy'
  elif revamped_has_command xclip; then
    printf 'xclip -selection clipboard -in'
  elif revamped_has_command xsel; then
    printf 'xsel --clipboard --input'
  fi
}

scroll_revamped_copymode_actions() {
  SCROLL_REVAMPED_UP=$(scroll_revamped_x_command up)
  SCROLL_REVAMPED_DOWN=$(scroll_revamped_x_command down)
  if [ "${SCROLL_REVAMPED_S_auto_exit}" = on ]; then
    SCROLL_REVAMPED_DOWN=$(printf "if-shell -F '#{?#{==:#{scroll_position},0},1,0}' 'send-keys -X cancel' '%s'" "${SCROLL_REVAMPED_DOWN}")
  fi
  if [ "${SCROLL_REVAMPED_S_indicator}" = on ] && scroll_revamped_at_least 3.2; then
    scroll_revamped_copymode_actions_say="display-message -d 700 'scroll #{scroll_position}/#{history_size}'"
    SCROLL_REVAMPED_UP="${SCROLL_REVAMPED_UP} ; ${scroll_revamped_copymode_actions_say}"
    SCROLL_REVAMPED_DOWN="${SCROLL_REVAMPED_DOWN} ; ${scroll_revamped_copymode_actions_say}"
  fi
}

scroll_revamped_ticks() {
  case "${SCROLL_REVAMPED_S_granularity}" in
  line | halfpage | page) : ;;
  *) SCROLL_REVAMPED_S_granularity=line ;;
  esac
  SCROLL_REVAMPED_SMOOTHED=0
  case "${SCROLL_REVAMPED_S_smooth}:${SCROLL_REVAMPED_S_granularity}:${SCROLL_REVAMPED_COUNT:-${SCROLL_REVAMPED_STOCK_LINES}}" in
  on:line:????*) : ;;
  on:line:*) ! scroll_revamped_at_least 3.2 || SCROLL_REVAMPED_SMOOTHED=1 ;;
  *) : ;;
  esac
  SCROLL_REVAMPED_TUNED=0
  case "${SCROLL_REVAMPED_S_granularity}:${SCROLL_REVAMPED_COUNT}:${SCROLL_REVAMPED_S_auto_exit}:${SCROLL_REVAMPED_S_indicator}:${SCROLL_REVAMPED_SMOOTHED}" in
  line::off:off:0) : ;;
  *) SCROLL_REVAMPED_TUNED=1 ;;
  esac
  scroll_revamped_copymode_actions
  SCROLL_REVAMPED_FIRST='send-keys -M'
  scroll_revamped_at_least 2.4 || return 0
  SCROLL_REVAMPED_FIRST="send-keys -X -N ${SCROLL_REVAMPED_STOCK_LINES} scroll-up"
  [ "${SCROLL_REVAMPED_TUNED}" -eq 0 ] || SCROLL_REVAMPED_FIRST="${SCROLL_REVAMPED_UP}"
}

scroll_revamped_plan_copymode() {
  scroll_revamped_at_least 2.4 || return 0
  scroll_revamped_plan_copymode_clip=""
  [ "${SCROLL_REVAMPED_S_drag_copy}" != on ] || scroll_revamped_plan_copymode_clip=$(scroll_revamped_clipboard)
  for scroll_revamped_plan_copymode_table in copy-mode copy-mode-vi; do
    if [ "${SCROLL_REVAMPED_TUNED}" -eq 1 ]; then
      scroll_revamped_emit bind-key -T "${scroll_revamped_plan_copymode_table}" WheelUpPane "${SCROLL_REVAMPED_UP}"
      scroll_revamped_emit bind-key -T "${scroll_revamped_plan_copymode_table}" WheelDownPane "${SCROLL_REVAMPED_DOWN}"
    fi
    [ -z "${scroll_revamped_plan_copymode_clip}" ] || scroll_revamped_emit bind-key -T "${scroll_revamped_plan_copymode_table}" MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "${scroll_revamped_plan_copymode_clip}"
  done
}

scroll_revamped_plan_clicks() {
  [ "${SCROLL_REVAMPED_S_click_copy}" = on ] || return 0
  scroll_revamped_at_least 3.2 || return 0
  scroll_revamped_plan_clicks_clip=$(scroll_revamped_clipboard)
  [ -n "${scroll_revamped_plan_clicks_clip}" ] || return 0
  scroll_revamped_plan_clicks_pass=$(scroll_revamped_or '#{pane_in_mode}' '#{mouse_any_flag}')
  for scroll_revamped_plan_clicks_pair in DoubleClick1Pane:select-word TripleClick1Pane:select-line; do
    scroll_revamped_plan_clicks_key="${scroll_revamped_plan_clicks_pair%%:*}"
    scroll_revamped_plan_clicks_copy="send-keys -X ${scroll_revamped_plan_clicks_pair#*:} ; run-shell -d ${SCROLL_REVAMPED_CLICK_SECONDS} ; send-keys -X copy-pipe-and-cancel '${scroll_revamped_plan_clicks_clip}'"
    scroll_revamped_emit bind-key -n "${scroll_revamped_plan_clicks_key}" "select-pane -t = ; if-shell -F \"#{?${scroll_revamped_plan_clicks_pass},1,0}\" \"send-keys -M\" \"copy-mode -H ; ${scroll_revamped_plan_clicks_copy}\""
    scroll_revamped_emit bind-key -T copy-mode "${scroll_revamped_plan_clicks_key}" "select-pane ; ${scroll_revamped_plan_clicks_copy}"
    scroll_revamped_emit bind-key -T copy-mode-vi "${scroll_revamped_plan_clicks_key}" "select-pane ; ${scroll_revamped_plan_clicks_copy}"
  done
}

scroll_revamped_plan_status() {
  [ "${SCROLL_REVAMPED_S_status_wheel}" = on ] || return 0
  scroll_revamped_at_least 2.1 || return 0
  scroll_revamped_emit bind-key -n WheelUpStatus previous-window
  scroll_revamped_emit bind-key -n WheelDownStatus next-window
}

scroll_revamped_plan() {
  scroll_revamped_load
  scroll_revamped_plan_raw=$(tmux -V 2>/dev/null) || scroll_revamped_plan_raw=""
  SCROLL_REVAMPED_TMUX=$(scroll_revamped_parse_version "${scroll_revamped_plan_raw}")
  SCROLL_REVAMPED_COUNT=$(scroll_revamped_valid_speed "${SCROLL_REVAMPED_S_speed}")
  SCROLL_REVAMPED_PLAN=""
  [ "${SCROLL_REVAMPED_S_mouse}" != on ] || scroll_revamped_emit set-option -g mouse on
  scroll_revamped_ticks
  scroll_revamped_plan_wheel
  scroll_revamped_plan_copymode
  scroll_revamped_plan_clicks
  scroll_revamped_plan_status
}

scroll_revamped_apply() {
  scroll_revamped_plan
  set --
  scroll_revamped_apply_sep=""
  while IFS= read -r scroll_revamped_apply_line; do
    if [ -z "${scroll_revamped_apply_line}" ]; then
      [ "$#" -eq 0 ] || scroll_revamped_apply_sep=";"
      continue
    fi
    [ -z "${scroll_revamped_apply_sep}" ] || set -- "$@" "${scroll_revamped_apply_sep}"
    scroll_revamped_apply_sep=""
    set -- "$@" "${scroll_revamped_apply_line}"
  done <<PLAN
${SCROLL_REVAMPED_PLAN}
PLAN
  [ "$#" -gt 0 ] || return 0
  tmux "$@" 2>/dev/null && return 0
  scroll_revamped_apply_each
}

scroll_revamped_apply_each() {
  scroll_revamped_apply_each_status=0
  set --
  while IFS= read -r scroll_revamped_apply_each_line; do
    if [ -n "${scroll_revamped_apply_each_line}" ]; then
      set -- "$@" "${scroll_revamped_apply_each_line}"
      continue
    fi
    [ "$#" -gt 0 ] || continue
    tmux "$@" || scroll_revamped_apply_each_status=1
    set --
  done <<PLAN
${SCROLL_REVAMPED_PLAN}
PLAN
  return "${scroll_revamped_apply_each_status}"
}

scroll_revamped_decide() {
  case "$1:$2:$3" in
  1:*:* | *:1:* | *:*:0) return 0 ;;
  *) return 1 ;;
  esac
}

scroll_revamped_check() {
  set -- "${1:-}" "${2:-}" "${3:-}" "${4:-}"
  scroll_revamped_check_key="$4|$1|$2|$3"
  scroll_revamped_check_cached=$(tmux display-message -p "#{${SCROLL_REVAMPED_CACHE_KEY}}	#{${SCROLL_REVAMPED_CACHE_VAL}}" 2>/dev/null) || scroll_revamped_check_cached=""
  case "${scroll_revamped_check_cached}" in
  "${scroll_revamped_check_key}	0") return 0 ;;
  "${scroll_revamped_check_key}	1") return 1 ;;
  *) : ;;
  esac
  scroll_revamped_check_decision=1
  ! scroll_revamped_decide "$1" "$2" "$3" || scroll_revamped_check_decision=0
  tmux set-option -gq "${SCROLL_REVAMPED_CACHE_KEY}" "${scroll_revamped_check_key}" \; set-option -gq "${SCROLL_REVAMPED_CACHE_VAL}" "${scroll_revamped_check_decision}"
  return "${scroll_revamped_check_decision}"
}

scroll_revamped_lines() {
  printf '%s' "${SCROLL_REVAMPED_PLAN}" | awk 'NF == 0 && line != "" { print line; line = ""; next } NF == 0 { next } { line = (line == "" ? $0 : line " " $0) } END { if (line != "") { print line } }'
}

scroll_revamped_json() {
  printf '%s' "${SCROLL_REVAMPED_PLAN}" | awk '
    function quote(s,    out, i, c) {
      out = ""
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c == "\\") { out = out "\\\\" } else if (c == "\"") { out = out "\\\"" } else { out = out c }
      }
      return "\"" out "\""
    }
    /^$/ { if (args != "") { rows = rows (rows == "" ? "" : ",") "[" args "]" } args = ""; next }
    { args = args (args == "" ? "" : ",") quote($0) }
    END {
      if (args != "") { rows = rows (rows == "" ? "" : ",") "[" args "]" }
      print "{\"bindings\":[" rows "]}"
    }
  '
}

scroll_revamped_bindings() {
  printf '%s' "${SCROLL_REVAMPED_PLAN}" | awk 'previous == "" && $0 == "bind-key" { count++ } { previous = $0 } END { print count + 0 }'
}

scroll_revamped_setting_name() {
  scroll_revamped_setting_name_raw=$(printf '%s\n' "${1#--}" | tr '-' '_')
  case " ${SCROLL_REVAMPED_NAMES} " in
  *" ${scroll_revamped_setting_name_raw} "*) printf '%s\n' "${scroll_revamped_setting_name_raw}" ;;
  *) printf '\n' ;;
  esac
}

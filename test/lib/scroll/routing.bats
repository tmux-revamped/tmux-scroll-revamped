#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _SCROLL_REVAMPED_LOADED
  unset _SCROLL_REVAMPED_ROUTING_LOADED
  unset _TMUX_PLUGIN_PLATFORM_LOADED
  unset _TMUX_PLUGIN_HAS_COMMAND_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/scroll/routing.sh"
  # Dry-run applier: record each tmux command as a bracketed line instead of
  # touching a live tmux. This is what every binding assertion reads.
  scroll_emit() {
    local out="tmux" a
    for a in "$@"; do out="${out} [${a}]"; done
    printf '%s\n' "${out}"
  }
}

teardown() {
  cleanup_test_environment
}

@test "routing - scroll_emit forwards to the tmux applier" {
  unset _SCROLL_REVAMPED_ROUTING_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/scroll/routing.sh"
  run scroll_emit show-option -gqv @scroll_revamped_nope
  [ "${status}" -eq 0 ]
}

@test "routing - functions are defined" {
  function_exists scroll_main
  function_exists scroll_build_wheel
  function_exists scroll_build_copymode
  function_exists scroll_build_status
  function_exists scroll_passthrough_condition
  function_exists scroll_passthrough_action
  function_exists scroll_clipboard_command
}

@test "routing - scroll_ge compares versions" {
  scroll_ge "3.1" "2.0"
  scroll_ge "2.0" "2.0"
  run scroll_ge "1.9" "2.0"
  [ "${status}" -eq 1 ]
}

@test "routing - scroll_or is native on 3.1+ and nested below" {
  [[ "$(scroll_or 3.5 A B)" == "#{||:A,B}" ]]
  [[ "$(scroll_or 2.4 A B)" == "#{?A,1,B}" ]]
}

@test "routing - scroll_and is native on 3.1+ and nested below" {
  [[ "$(scroll_and 3.5 A B)" == "#{&&:A,B}" ]]
  [[ "$(scroll_and 2.4 A B)" == "#{?A,B,0}" ]]
}

@test "routing - scroll_not negates a condition" {
  [[ "$(scroll_not X)" == "#{?X,0,1}" ]]
}

@test "routing - scroll_tmux_version reads tmux -V" {
  run scroll_tmux_version
  [ "${status}" -eq 0 ]
}

@test "routing - passthrough condition includes alternate and mouse by default" {
  local c
  c="$(scroll_passthrough_condition 3.5 on on off)"
  [[ "${c}" == *"alternate_on"* ]]
  [[ "${c}" == *"mouse_any_flag"* ]]
  [[ "${c}" == *"pane_in_mode"* ]]
  [[ "${c}" != *"history_size"* ]]
}

@test "routing - passthrough condition drops disabled heuristics" {
  local c
  c="$(scroll_passthrough_condition 3.5 off off off)"
  [[ "${c}" != *"alternate_on"* ]]
  [[ "${c}" != *"mouse_any_flag"* ]]
  [[ "${c}" == *"pane_in_mode"* ]]
}

@test "routing - skip_empty adds history_size to the condition" {
  local c
  c="$(scroll_passthrough_condition 2.4 on on on)"
  [[ "${c}" == *"history_size"* ]]
}

@test "routing - passthrough action defaults to mouse passthrough" {
  [[ "$(scroll_passthrough_action 3.5 "" "" up)" == "send-keys -M" ]]
}

@test "routing - arrow action sends count up keys for alt no-mouse panes" {
  local a
  a="$(scroll_passthrough_action 3.5 arrow 3 up)"
  [[ "${a}" == *"send-keys Up Up Up"* ]]
  [[ "${a}" == *"alternate_on"* ]]
  [[ "${a}" == *"mouse_any_flag"* ]]
  [[ "${a}" == *"send-keys -M"* ]]
}

@test "routing - arrow action down uses Down" {
  [[ "$(scroll_passthrough_action 3.5 arrow 2 down)" == *"send-keys Down Down"* ]]
}

@test "routing - page action sends a single page key" {
  [[ "$(scroll_passthrough_action 3.5 page 5 up)" == *"send-keys PageUp'"* ]]
  [[ "$(scroll_passthrough_action 3.5 page 5 down)" == *"send-keys PageDown'"* ]]
}

@test "routing - alt keys are ignored below tmux 2.0" {
  [[ "$(scroll_passthrough_action 1.9 arrow 3 up)" == "send-keys -M" ]]
}

@test "routing - clipboard prefers pbcopy on macOS" {
  is_macos() { return 0; }
  has_command() { [[ "${1}" == "pbcopy" ]]; }
  [[ "$(scroll_clipboard_command)" == "pbcopy" ]]
}

@test "routing - clipboard falls back to wl-copy then xclip then xsel" {
  is_macos() { return 1; }
  has_command() { [[ "${1}" == "wl-copy" ]]; }
  [[ "$(scroll_clipboard_command)" == "wl-copy" ]]
  has_command() { [[ "${1}" == "xclip" ]]; }
  [[ "$(scroll_clipboard_command)" == "xclip -selection clipboard -in" ]]
  has_command() { [[ "${1}" == "xsel" ]]; }
  [[ "$(scroll_clipboard_command)" == "xsel --clipboard --input" ]]
}

@test "routing - clipboard is empty when nothing is available" {
  is_macos() { return 1; }
  has_command() { return 1; }
  [[ -z "$(scroll_clipboard_command)" ]]
}

@test "routing - wheel default 3.x keeps native fork-free routing" {
  local out
  out="$(scroll_build_wheel 3.5)"
  [[ "${out}" == *"WheelUpPane"* ]]
  [[ "${out}" == *"if-shell -F"* ]]
  [[ "${out}" == *"#{||:"* ]]
  [[ "${out}" == *"copy-mode -e ; send-keys -M"* ]]
  [[ "${out}" == *"WheelDownPane] [send-keys -M"* ]]
  [[ "${out}" != *"select-pane"* ]]
}

@test "routing - select_pane prepends select-pane on both wheels" {
  set_tmux_option "@scroll_revamped_select_pane" "on"
  local out
  out="$(scroll_build_wheel 3.5)"
  [[ "${out}" == *"WheelUpPane] [select-pane -t = ;"* ]]
  [[ "${out}" == *"WheelDownPane] [select-pane -t = ;"* ]]
}

@test "routing - alt_keys arrow nests an arrow-key branch into the wheel" {
  set_tmux_option "@scroll_revamped_alt_keys" "arrow"
  local out
  out="$(scroll_build_wheel 3.5)"
  [[ "${out}" == *"send-keys Up Up Up"* ]]
  [[ "${out}" == *"send-keys Down Down Down"* ]]
}

@test "routing - 2.x wheel uses nested conditional without #{||:}" {
  local out
  out="$(scroll_build_wheel 2.4)"
  [[ "${out}" == *"if-shell -F"* ]]
  [[ "${out}" != *"#{||:"* ]]
  [[ "${out}" == *"#{?#{alternate_on}"* ]]
}

@test "routing - 1.9 wheel forks the cached check command" {
  local out
  out="$(scroll_build_wheel 1.9)"
  [[ "${out}" == *"src/scroll.sh check"* ]]
  [[ "${out}" == *"pane_id"* ]]
  [[ "${out}" == *"WheelDownPane] [send-keys -M"* ]]
}

@test "routing - 1.9 wheel passes history_size only when skip_empty is on" {
  set_tmux_option "@scroll_revamped_skip_empty" "on"
  local out
  out="$(scroll_build_wheel 1.9)"
  [[ "${out}" == *"history_size"* ]]
}

@test "routing - _scroll_x_command maps granularity and direction" {
  [[ "$(_scroll_x_command "" line up)" == "send-keys -X scroll-up" ]]
  [[ "$(_scroll_x_command "" line down)" == "send-keys -X scroll-down" ]]
  [[ "$(_scroll_x_command 5 line up)" == "send-keys -X -N 5 scroll-up" ]]
  [[ "$(_scroll_x_command "" halfpage up)" == "send-keys -X halfpage-up" ]]
  [[ "$(_scroll_x_command "" page down)" == "send-keys -X page-down" ]]
}

@test "routing - copymode emits nothing by default" {
  [[ -z "$(scroll_build_copymode 3.5)" ]]
}

@test "routing - copymode is skipped below tmux 2.4" {
  set_tmux_option "@scroll_revamped_granularity" "page"
  [[ -z "$(scroll_build_copymode 2.3)" ]]
}

@test "routing - copymode honors granularity and throttle" {
  set_tmux_option "@scroll_revamped_granularity" "halfpage"
  set_tmux_option "@scroll_revamped_speed" "4"
  local out
  out="$(scroll_build_copymode 3.5)"
  [[ "${out}" == *"copy-mode] [WheelUpPane] [send-keys -X halfpage-up"* ]]
  [[ "${out}" == *"copy-mode-vi] [WheelUpPane]"* ]]
}

@test "routing - copymode line granularity applies the throttle count" {
  set_tmux_option "@scroll_revamped_speed" "7"
  local out
  out="$(scroll_build_copymode 3.5)"
  [[ "${out}" == *"send-keys -X -N 7 scroll-up"* ]]
}

@test "routing - copymode auto_exit cancels at the bottom" {
  set_tmux_option "@scroll_revamped_auto_exit" "on"
  local out
  out="$(scroll_build_copymode 3.5)"
  [[ "${out}" == *"scroll_position"* ]]
  [[ "${out}" == *"send-keys -X cancel"* ]]
}

@test "routing - indicator is shown on 2.9+ and gated below" {
  set_tmux_option "@scroll_revamped_indicator" "on"
  local out_modern out_old
  out_modern="$(scroll_build_copymode 3.5)"
  [[ "${out_modern}" == *"display-message -d 700"* ]]
  out_old="$(scroll_build_copymode 2.4)"
  [[ "${out_old}" == *"WheelUpPane"* ]]
  [[ "${out_old}" != *"display-message"* ]]
}

@test "routing - drag_copy binds copy-pipe-and-cancel when a clipboard exists" {
  set_tmux_option "@scroll_revamped_drag_copy" "on"
  scroll_clipboard_command() { printf 'pbcopy'; }
  local out
  out="$(scroll_build_copymode 3.5)"
  [[ "${out}" == *"MouseDragEnd1Pane] [send-keys] [-X] [copy-pipe-and-cancel] [pbcopy]"* ]]
}

@test "routing - drag_copy binds nothing when no clipboard is found" {
  set_tmux_option "@scroll_revamped_drag_copy" "on"
  scroll_clipboard_command() { printf ''; }
  [[ -z "$(scroll_build_copymode 3.5)" ]]
}

@test "routing - granularity falls back to line on a bad value" {
  set_tmux_option "@scroll_revamped_granularity" "bogus"
  [[ -z "$(scroll_build_copymode 3.5)" ]]
}

@test "routing - status wheel switches windows when enabled" {
  set_tmux_option "@scroll_revamped_status_wheel" "on"
  local out
  out="$(scroll_build_status 3.5)"
  [[ "${out}" == *"WheelUpStatus] [previous-window]"* ]]
  [[ "${out}" == *"WheelDownStatus] [next-window]"* ]]
}

@test "routing - status wheel is off by default and gated below 2.1" {
  [[ -z "$(scroll_build_status 3.5)" ]]
  set_tmux_option "@scroll_revamped_status_wheel" "on"
  [[ -z "$(scroll_build_status 1.9)" ]]
}

@test "routing - scroll_main wires mouse and every binding set" {
  scroll_tmux_version() { printf '3.5'; }
  set_tmux_option "@scroll_revamped_status_wheel" "on"
  set_tmux_option "@scroll_revamped_granularity" "page"
  local out
  out="$(scroll_main)"
  [[ "${out}" == *"set-option] [-g] [mouse] [on]"* ]]
  [[ "${out}" == *"WheelUpPane"* ]]
  [[ "${out}" == *"WheelUpStatus"* ]]
  [[ "${out}" == *"copy-mode] [WheelUpPane] [send-keys -X page-up"* ]]
}

@test "routing - scroll_main leaves mouse alone when opted out" {
  scroll_tmux_version() { printf '3.5'; }
  set_tmux_option "@scroll_revamped_mouse" "off"
  local out
  out="$(scroll_main)"
  [[ "${out}" != *"mouse] [on]"* ]]
}

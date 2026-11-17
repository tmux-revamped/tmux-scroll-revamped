#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034

# shellcheck source=test/scroll_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/scroll_helpers.bash"

@test "scroll - copy-mode keeps tmux's own wheel by default" {
  # Arrange
  option mouse off

  # Act
  plan_at 3.6

  # Assert
  [[ -z "${output}" ]]
}

@test "scroll - copy-mode is left alone before 2.4" {
  # Arrange
  option speed 3
  option mouse off

  # Act
  plan_at 2.3

  # Assert
  [[ -z "${output}" ]]
}

@test "scroll - a line speed scrolls that many lines in both copy-mode tables" {
  # Arrange
  option speed 3
  option mouse off

  # Act
  plan_at 3.6

  # Assert
  [[ "${lines[0]}" == "bind-key -T copy-mode WheelUpPane send-keys -X -N 3 scroll-up" ]]
  [[ "${lines[3]}" == "bind-key -T copy-mode-vi WheelDownPane send-keys -X -N 3 scroll-down" ]]
}

@test "scroll - halfpage granularity ignores the speed" {
  # Arrange
  option granularity halfpage
  option speed 3
  option mouse off

  # Act
  plan_at 3.6

  # Assert
  [[ "${lines[0]}" == "bind-key -T copy-mode WheelUpPane send-keys -X halfpage-up" ]]
}

@test "scroll - page granularity scrolls a whole page in both tables" {
  # Arrange
  option granularity page
  option mouse off

  # Act
  plan_at 3.6

  # Assert
  [[ "${lines[0]}" == "bind-key -T copy-mode WheelUpPane send-keys -X page-up" ]]
  [[ "${lines[3]}" == "bind-key -T copy-mode-vi WheelDownPane send-keys -X page-down" ]]
}

@test "scroll - a bad granularity falls back to line" {
  # Arrange
  option granularity sideways
  option auto_exit on
  option mouse off

  # Act
  plan_at 3.6

  # Assert
  [[ "${lines[0]}" == "bind-key -T copy-mode WheelUpPane send-keys -X scroll-up" ]]
  [[ "${lines[1]}" == "bind-key -T copy-mode WheelDownPane if-shell -F '#{?#{==:#{scroll_position},0},1,0}' 'send-keys -X cancel' 'send-keys -X scroll-down'" ]]
}

@test "scroll - the indicator shows on 3.2 and is skipped on 3.1" {
  # Arrange
  option indicator on
  option mouse off
  export REVAMPED_TEST_TMUX_VERSION=3.2

  # Act
  lib_run scroll 'scroll_revamped_plan; scroll_revamped_lines; export REVAMPED_TEST_TMUX_VERSION=3.1; scroll_revamped_plan; scroll_revamped_lines'

  # Assert
  [[ "${lines[0]}" == "bind-key -T copy-mode WheelUpPane send-keys -X scroll-up ; display-message -d 700 'scroll #{scroll_position}/#{history_size}'" ]]
  [[ "${lines[4]}" == "bind-key -T copy-mode WheelUpPane send-keys -X scroll-up" ]]
}

@test "scroll - drag copy pipes the selection to the clipboard tool" {
  # Arrange
  option drag_copy on
  option mouse off
  stub_command wl-copy
  harness_hide pbcopy xclip xsel
  export REVAMPED_TEST_UNAME_S=Linux REVAMPED_TEST_TMUX_VERSION=3.6

  # Act
  lib_run scroll 'scroll_revamped_plan; scroll_revamped_lines'

  # Assert
  [[ "${lines[0]}" == "bind-key -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel wl-copy" ]]
  [[ "${lines[1]}" == "bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel wl-copy" ]]
}

@test "scroll - drag copy binds nothing without a clipboard tool" {
  # Arrange
  option drag_copy on
  option mouse off
  harness_hide pbcopy wl-copy xclip xsel
  export REVAMPED_TEST_TMUX_VERSION=3.6

  # Act
  lib_run scroll 'scroll_revamped_plan; scroll_revamped_lines'

  # Assert
  [[ -z "${output}" ]]
}

@test "scroll - click copy binds double and triple click in the root and both copy-mode tables" {
  # Arrange
  option click_copy on
  option mouse off
  stub_command wl-copy
  harness_hide pbcopy xclip xsel
  export REVAMPED_TEST_UNAME_S=Linux REVAMPED_TEST_TMUX_VERSION=3.6

  # Act
  lib_run scroll 'scroll_revamped_plan; scroll_revamped_lines'

  # Assert
  [[ "${lines[0]}" == 'bind-key -n DoubleClick1Pane select-pane -t = ; if-shell -F "#{?#{||:#{pane_in_mode},#{mouse_any_flag}},1,0}" "send-keys -M" "copy-mode -H ; send-keys -X select-word ; run-shell -d 0.3 ; send-keys -X copy-pipe-and-cancel '"'wl-copy'"'"' ]] || false
  [[ "${lines[1]}" == "bind-key -T copy-mode DoubleClick1Pane select-pane ; send-keys -X select-word ; run-shell -d 0.3 ; send-keys -X copy-pipe-and-cancel 'wl-copy'" ]] || false
  [[ "${lines[2]}" == "bind-key -T copy-mode-vi DoubleClick1Pane select-pane ; send-keys -X select-word ; run-shell -d 0.3 ; send-keys -X copy-pipe-and-cancel 'wl-copy'" ]] || false
  [[ "${lines[3]}" == 'bind-key -n TripleClick1Pane select-pane -t = ; if-shell -F "#{?#{||:#{pane_in_mode},#{mouse_any_flag}},1,0}" "send-keys -M" "copy-mode -H ; send-keys -X select-line ; run-shell -d 0.3 ; send-keys -X copy-pipe-and-cancel '"'wl-copy'"'"' ]] || false
  [[ "${lines[4]}" == "bind-key -T copy-mode TripleClick1Pane select-pane ; send-keys -X select-line ; run-shell -d 0.3 ; send-keys -X copy-pipe-and-cancel 'wl-copy'" ]] || false
  [[ "${#lines[@]}" -eq 6 ]]
}

@test "scroll - click copy binds nothing before tmux 3.2" {
  # Arrange
  option click_copy on
  option mouse off
  stub_command wl-copy
  harness_hide pbcopy xclip xsel
  export REVAMPED_TEST_UNAME_S=Linux REVAMPED_TEST_TMUX_VERSION=3.1

  # Act
  lib_run scroll 'scroll_revamped_plan; scroll_revamped_lines'

  # Assert
  [[ -z "${output}" ]]
}

@test "scroll - click copy binds nothing without a clipboard tool" {
  # Arrange
  option click_copy on
  option mouse off
  harness_hide pbcopy wl-copy xclip xsel
  export REVAMPED_TEST_TMUX_VERSION=3.6

  # Act
  lib_run scroll 'scroll_revamped_plan; scroll_revamped_lines'

  # Assert
  [[ -z "${output}" ]]
}

@test "scroll - the clipboard prefers pbcopy on macOS, then wl-copy, xclip and xsel" {
  # Arrange
  stub_command pbcopy
  stub_command xclip
  stub_command xsel
  harness_hide wl-copy
  local script='printf "[%s]" "$(REVAMPED_TEST_UNAME_S=Darwin scroll_revamped_clipboard)"; printf "[%s]" "$(REVAMPED_TEST_UNAME_S=Linux scroll_revamped_clipboard)"; rm -f "${BATS_TEST_TMPDIR}/stubs/xclip"; printf "[%s]" "$(REVAMPED_TEST_UNAME_S=Linux scroll_revamped_clipboard)"'

  # Act
  lib_run scroll "${script}"

  # Assert
  [[ "${output}" == "[pbcopy][xclip -selection clipboard -in][xsel --clipboard --input]" ]]
}

@test "scroll - the status wheel switches windows on 2.1 and later" {
  # Arrange
  option status_wheel on
  option mouse off
  export REVAMPED_TEST_TMUX_VERSION=2.1

  # Act
  lib_run scroll 'scroll_revamped_plan; scroll_revamped_lines; export REVAMPED_TEST_TMUX_VERSION=2.0; scroll_revamped_plan; printf "[%s]" "$(scroll_revamped_lines)"'

  # Assert
  [[ "${lines[0]}" == "bind-key -n WheelUpStatus previous-window" ]]
  [[ "${lines[1]}" == "bind-key -n WheelDownStatus next-window" ]]
  [[ "${lines[2]}" == "[]" ]]
}

@test "scroll - apply sends every binding to tmux in one call" {
  # Arrange
  option wheel on
  option speed 3
  export REVAMPED_TEST_TMUX_ARGV="${BATS_TEST_TMPDIR}/argv"

  # Act
  lib_run scroll scroll_revamped_apply

  # Assert
  run grep -c '^set-option|-g|mouse|on|;|bind-key' "${REVAMPED_TEST_TMUX_ARGV}"
  [[ "${output}" == "1" ]]
}

@test "scroll - apply calls tmux for nothing when nothing is set" {
  # Arrange
  option mouse off
  export REVAMPED_TEST_TMUX_ARGV="${BATS_TEST_TMPDIR}/argv"

  # Act
  lib_run scroll scroll_revamped_apply

  # Assert
  [[ "${status}" -eq 0 ]]
  run grep -c '^bind-key\|^set-option' "${REVAMPED_TEST_TMUX_ARGV}"
  [[ "${output}" == "0" ]]
}

@test "scroll - json lists every command as its arguments" {
  # Arrange
  option mouse off
  option status_wheel on

  # Act
  lib_run scroll 'scroll_revamped_plan; scroll_revamped_json'

  # Assert
  [[ "${output}" == '{"bindings":[["bind-key","-n","WheelUpStatus","previous-window"],["bind-key","-n","WheelDownStatus","next-window"]]}' ]]
}

@test "scroll - json escapes quotes and backslashes" {
  # Arrange
  local script='SCROLL_REVAMPED_PLAN="$(printf "a\\\\b\nsay \"hi\"\n\n")"; scroll_revamped_json'

  # Act
  lib_run scroll "${script}"

  # Assert
  [[ "${output}" == '{"bindings":[["a\\b","say \"hi\""]]}' ]]
}

@test "scroll - bindings counts the bind-key commands" {
  # Arrange
  option wheel on

  # Act
  lib_run scroll 'scroll_revamped_plan; scroll_revamped_bindings'

  # Assert
  [[ "${output}" == "2" ]]
}

@test "scroll - a setting name comes from its long option" {
  # Arrange
  local script='for o in --wheel --passthrough-alternate --colour; do printf "[%s]" "$(scroll_revamped_setting_name "$o")"; done'

  # Act
  lib_run scroll "${script}"

  # Assert
  [[ "${output}" == "[wheel][passthrough_alternate][]" ]]
}

@test "scroll - a setting comes from the environment, then the tmux option, then its default" {
  # Arrange
  option speed 5
  option granularity page
  export SCROLL_REVAMPED_SPEED=7

  # Act
  lib_run scroll 'scroll_revamped_load; printf "[%s][%s][%s]" "${SCROLL_REVAMPED_S_speed}" "${SCROLL_REVAMPED_S_granularity}" "${SCROLL_REVAMPED_S_wheel}"'

  # Assert
  [[ "${output}" == "[7][page][off]" ]]
}

@test "check - an alternate screen, an app's mouse or an empty scrollback pass the wheel" {
  # Arrange
  local script='for f in "1 0 5" "0 1 5" "0 0 0" "0 0 5" "0 0 "; do set -- ${f}; if scroll_revamped_decide "$1" "$2" "${3:-}"; then printf p; else printf c; fi; done'

  # Act
  lib_run scroll "${script}"

  # Assert
  [[ "${output}" == "pppcc" ]]
}

@test "check - a cached pass is answered without a new decision" {
  # Arrange
  option cache_key '%2|1|0|'
  option cache_val 0

  # Act
  lib_run scroll 'scroll_revamped_check 1 0 "" %2'

  # Assert
  [[ "${status}" -eq 0 ]]
  run grep -c '^set-option' "${REVAMPED_TEST_TMUX_LOG}"
  [[ "${output}" == "0" ]]
}

@test "check - a corrupt cached value is decided again" {
  # Arrange
  option cache_key '%3|0|0|0'
  option cache_val 7

  # Act
  lib_run scroll 'scroll_revamped_check 0 0 0 %3'

  # Assert
  [[ "${status}" -eq 0 ]]
  run grep -c '^set-option' "${REVAMPED_TEST_TMUX_LOG}"
  [[ "${output}" == "1" ]]
}

@test "scroll - each command is sent alone when the one call fails" {
  # Arrange
  refuse
  option wheel on
  export REVAMPED_TEST_TMUX_ARGV="${BATS_TEST_TMPDIR}/argv"

  # Act
  lib_run scroll scroll_revamped_apply

  # Assert
  [[ "${status}" -eq 0 ]]
  run grep -c '|;|' "${REVAMPED_TEST_TMUX_ARGV}"
  [[ "${output}" == "0" ]]
  run grep -c '^bind-key\|^set-option' "${REVAMPED_TEST_TMUX_ARGV}"
  [[ "${output}" -ge 2 ]]
}

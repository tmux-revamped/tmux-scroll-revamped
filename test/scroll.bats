#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
  for name in $(compgen -v SCROLL_REVAMPED_); do
    unset "${name}"
  done
}

option() {
  printf '%s' "$2" >"${REVAMPED_TEST_TMUX_DIR}/$(printf '%s' "g.-.@scroll_revamped_$1" | tr -c 'A-Za-z0-9_.-' '_')"
}

plan_at() {
  export REVAMPED_TEST_TMUX_VERSION="$1"
  lib_run scroll 'scroll_revamped_plan; scroll_revamped_lines'
}

refuse() {
  mkdir -p "${BATS_TEST_TMPDIR}/stubs"
  printf '#!/bin/sh\nfor a in "$@"; do [ "$a" != ";" ] || exit 1; [ "$a" != BAD ] || { printf "unknown key: BAD\\n" >&2; exit 1; }; done\nexec "%s/bin/tmux" "$@"\n' "${REVAMPED_TESTS_DIR}" >"${BATS_TEST_TMPDIR}/stubs/tmux"
  chmod +x "${BATS_TEST_TMPDIR}/stubs/tmux"
}

@test "scroll - the version is read from tmux -V, next and rc builds included" {
  # Arrange
  local script='for v in "tmux 3.6" "tmux next-3.7" "tmux 3.5a" "tmux master"; do printf "[%s]" "$(scroll_revamped_parse_version "${v}")"; done'

  # Act
  lib_run scroll "${script}"

  # Assert
  [[ "${output}" == "[3.6][3.7][3.5][]" ]]
}

@test "scroll - version_ge compares major and minor numbers" {
  # Arrange
  local script='for p in "3.2 3.2" "3.10 3.2" "4.0 3.9" "3.1 3.2" "2.9 3.0" "x 3.2" ""; do set -- ${p}; if scroll_revamped_version_ge "${1:-}" "${2:-}"; then printf y; else printf n; fi; done'

  # Act
  lib_run scroll "${script}"

  # Assert
  [[ "${output}" == "yyynnnn" ]]
}

@test "scroll - a speed is a positive whole number or nothing" {
  # Arrange
  local script='for s in 3 10 0 07 -1 x ""; do printf "[%s]" "$(scroll_revamped_valid_speed "${s}")"; done'

  # Act
  lib_run scroll "${script}"

  # Assert
  [[ "${output}" == "[3][10][][][][][]" ]]
}

@test "scroll - the defaults turn the mouse on and bind no wheel key" {
  # Arrange
  local version=3.6

  # Act
  plan_at "${version}"

  # Assert
  [[ "${output}" == "set-option -g mouse on" ]]
}

@test "scroll - mouse off leaves tmux's mouse option alone" {
  # Arrange
  option mouse off

  # Act
  plan_at 3.6

  # Assert
  [[ -z "${output}" ]]
}

@test "scroll - the wheel on 3.1 and later decides with native or and passes by default" {
  # Arrange
  option wheel on

  # Act
  plan_at 3.6

  # Assert
  [[ "${lines[1]}" == 'bind-key -n WheelUpPane if-shell -F "#{?#{||:#{alternate_on},#{||:#{mouse_any_flag},#{pane_in_mode}}},1,0}" "send-keys -M" "copy-mode -e ; send-keys -M"' ]]
  [[ "${lines[2]}" == "bind-key -n WheelDownPane send-keys -M" ]]
}

@test "scroll - the wheel before 3.1 nests the conditions" {
  # Arrange
  option wheel on

  # Act
  plan_at 2.9

  # Assert
  [[ "${lines[1]}" == 'bind-key -n WheelUpPane if-shell -F "#{?#{?#{alternate_on},1,#{?#{mouse_any_flag},1,#{pane_in_mode}}},1,0}" "send-keys -M" "copy-mode -e ; send-keys -M"' ]]
}

@test "scroll - disabled passthroughs and skip-empty shape the condition" {
  # Arrange
  option wheel on
  option passthrough_alternate off
  option passthrough_mouse off
  option skip_empty on

  # Act
  plan_at 3.6

  # Assert
  [[ "${lines[1]}" == *'"#{?#{||:#{==:#{history_size},0},#{pane_in_mode}},1,0}"'* ]]
}

@test "scroll - select-pane comes first on both wheel keys" {
  # Arrange
  option wheel on
  option select_pane on

  # Act
  plan_at 3.6

  # Assert
  [[ "${lines[1]}" == "bind-key -n WheelUpPane select-pane -t = ; if-shell"* ]]
  [[ "${lines[2]}" == "bind-key -n WheelDownPane select-pane -t = ; send-keys -M" ]]
}

@test "scroll - arrow keys repeat the speed, three by default" {
  # Arrange
  option wheel on
  option alt_keys arrow

  # Act
  plan_at 3.6

  # Assert
  [[ "${lines[1]}" == *"'send-keys Up Up Up'"* ]]
  [[ "${lines[2]}" == "bind-key -n WheelDownPane if-shell -F '#{?#{&&:#{alternate_on},#{?#{mouse_any_flag},0,1}},1,0}' 'send-keys Down Down Down' 'send-keys -M'" ]]
}

@test "scroll - arrow keys are capped at twenty for a huge speed" {
  # Arrange
  option wheel on
  option alt_keys arrow
  option speed 99999999999999999999

  # Act
  plan_at 3.6

  # Assert
  [[ "${lines[2]}" == *"'send-keys Down Down Down Down Down Down Down Down Down Down Down Down Down Down Down Down Down Down Down Down'"* ]]
}

@test "scroll - arrow keys are capped at twenty for a two-digit speed" {
  # Arrange
  option wheel on
  option alt_keys arrow
  option speed 25

  # Act
  plan_at 3.6

  # Assert
  run grep -o ' Down' <<<"${lines[2]}"
  [[ "${#lines[@]}" -eq 20 ]]
}

@test "scroll - page keys send one page key and nest before 3.1" {
  # Arrange
  option wheel on
  option alt_keys page

  # Act
  plan_at 3.0

  # Assert
  [[ "${lines[2]}" == "bind-key -n WheelDownPane if-shell -F '#{?#{?#{alternate_on},#{?#{mouse_any_flag},0,1},0},1,0}' 'send-keys PageDown' 'send-keys -M'" ]]
}

@test "scroll - alt keys are ignored before tmux 2.0" {
  # Arrange
  option wheel on
  option alt_keys arrow

  # Act
  plan_at 1.9

  # Assert
  [[ "${lines[2]}" == "bind-key -n WheelDownPane send-keys -M" ]]
}

@test "scroll - the wheel before 2.0 runs the cached check with the flags it uses" {
  # Arrange
  option wheel on
  option skip_empty on

  # Act
  plan_at 1.9

  # Assert
  [[ "${lines[1]}" == "bind-key -n WheelUpPane if-shell \"'"*"/bin/scroll-revamped' check '#{alternate_on}' '#{mouse_any_flag}' '#{history_size}' '#{pane_id}'\" \"send-keys -M\" \"copy-mode -e ; send-keys -M\"" ]]
}

@test "scroll - the check before 2.0 leaves out what its options turn off" {
  # Arrange
  option wheel on
  option passthrough_alternate off
  option passthrough_mouse off

  # Act
  plan_at 1.9

  # Assert
  [[ "${lines[1]}" == *" check '0' '0' '' '#{pane_id}'"* ]]
}

@test "scroll - the tool path is quoted for sh inside a tmux double-quoted string" {
  # Arrange
  export PROBE_LIB='/tmp/it'"'"'s "a" $x #1\b/lib'

  # Act
  lib_run scroll 'REVAMPED_LIB="${PROBE_LIB}"; scroll_revamped_tool'

  # Assert
  [[ "${output}" == "'/tmp/it'\\\\''s \\\"a\\\" \\\$x ##1\\\\b/bin/scroll-revamped'" ]]
}

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

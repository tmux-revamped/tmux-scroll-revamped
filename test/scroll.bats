#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034

# shellcheck source=test/scroll_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/scroll_helpers.bash"

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
  [[ "${lines[1]}" == 'bind-key -n WheelUpPane if-shell -F "#{?#{||:#{alternate_on},#{||:#{mouse_any_flag},#{pane_in_mode}}},1,0}" "send-keys -M" "copy-mode -e ; send-keys -X -N 5 scroll-up"' ]]
  [[ "${lines[2]}" == "bind-key -n WheelDownPane send-keys -M" ]]
}

@test "scroll - the wheel before 3.1 nests the conditions" {
  # Arrange
  option wheel on

  # Act
  plan_at 2.9

  # Assert
  [[ "${lines[1]}" == 'bind-key -n WheelUpPane if-shell -F "#{?#{?#{alternate_on},1,#{?#{mouse_any_flag},1,#{pane_in_mode}}},1,0}" "send-keys -M" "copy-mode -e ; send-keys -X -N 5 scroll-up"' ]]
}

@test "scroll - the first tick into copy-mode scrolls tmux's five lines when nothing tunes the tick" {
  # Arrange
  option wheel on

  # Act
  plan_at 3.6

  # Assert
  [[ "${lines[1]}" == *'"copy-mode -e ; send-keys -X -N 5 scroll-up"' ]]
}

@test "scroll - the first tick into copy-mode runs the tuned tick when the speed is set" {
  # Arrange
  option wheel on
  option speed 7

  # Act
  plan_at 3.6

  # Assert
  [[ "${lines[1]}" == *'"copy-mode -e ; send-keys -X -N 7 scroll-up"' ]]
}

@test "scroll - before tmux 2.4 the first tick into copy-mode forwards the mouse event" {
  # Arrange
  option wheel on
  option speed 7

  # Act
  plan_at 2.3

  # Assert
  [[ "${lines[1]}" == *'"copy-mode -e ; send-keys -M"' ]]
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

@test "scroll - a smooth setting given in the environment is the one the settings read" {
  # Arrange
  export SCROLL_REVAMPED_SMOOTH=on

  # Act
  lib_run scroll 'scroll_revamped_load; printf "[%s]\n" "${SCROLL_REVAMPED_S_smooth}"'

  # Assert
  [[ "${output}" == "[on]" ]]
}

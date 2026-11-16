#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031,SC2034

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

bats_require_minimum_version 1.5.0

setup() {
  harness_setup
  for name in $(compgen -v SCROLL_REVAMPED_) KODOUGU_THEME KODOUGU_ACCENT NO_COLOR; do
    unset "${name}"
  done
}

tool() {
  # shellcheck disable=SC2086
  run ${REVAMPED_TEST_SHELL:-sh} "${REVAMPED_TESTS_DIR}/../bin/scroll-revamped" "$@"
}

plain_tty() {
  local shell_words
  read -r -a shell_words <<<"${REVAMPED_TEST_SHELL:-sh}"
  run python3 "${REVAMPED_TESTS_DIR}/on_tty.py" "${shell_words[@]}" "${REVAMPED_TESTS_DIR}/../bin/scroll-revamped"
}

@test "commands - list prints every binding apply would make" {
  # Arrange
  local command=list

  # Act
  tool "${command}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "set-option -g mouse on" ]]
}

@test "commands - list --json prints one JSON object" {
  # Arrange
  export SCROLL_REVAMPED_STATUS_WHEEL=on SCROLL_REVAMPED_MOUSE=off

  # Act
  tool list --json

  # Assert
  [[ "${output}" == '{"bindings":[["bind-key","-n","WheelUpStatus","previous-window"],["bind-key","-n","WheelDownStatus","next-window"]]}' ]]
}

@test "commands - an option in both forms wins over the environment" {
  # Arrange
  export SCROLL_REVAMPED_SPEED=9

  # Act
  tool --speed=2 --granularity line list

  # Assert
  [[ "${output}" == *"send-keys -X -N 2 scroll-up"* ]]
}

@test "commands - apply sends the plan in one tmux call and prints nothing" {
  # Arrange
  export REVAMPED_TEST_TMUX_ARGV="${BATS_TEST_TMPDIR}/argv"

  # Act
  # shellcheck disable=SC2086
  run --separate-stderr ${REVAMPED_TEST_SHELL:-sh} "${REVAMPED_TESTS_DIR}/../bin/scroll-revamped" apply

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
  run grep -c '^set-option|-g|mouse|on$' "${REVAMPED_TEST_TMUX_ARGV}"
  [[ "${output}" == "1" ]]
}

@test "commands - the menu applies the keys and counts them" {
  # Arrange
  harness_hide gum

  # Act
  plain_tty <<<"2"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Applied. 0 keys are bound."* ]]
}

@test "commands - the menu runs doctor" {
  # Arrange
  harness_hide gum

  # Act
  plain_tty <<<"3"

  # Assert
  [[ "${output}" =~ tmux\ +ok ]]
}

@test "commands - an unknown option is a usage error even without a value" {
  # Arrange
  local option=--colour

  # Act
  tool "${option}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "scroll-revamped: unknown option '--colour'. run 'scroll-revamped help' for usage." ]]
}

@test "commands - an unknown option with a value is a usage error" {
  # Arrange
  local option=--colour=red

  # Act
  tool "${option}" list

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "scroll-revamped: unknown option '--colour'. run 'scroll-revamped help' for usage." ]]
}

@test "commands - a setting option without its value is a usage error" {
  # Arrange
  local option=--speed

  # Act
  tool list "${option}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "scroll-revamped: option '--speed' needs a value. run 'scroll-revamped help' for usage." ]]
}

@test "commands - a single-dash option is a usage error" {
  # Arrange
  local option=-x

  # Act
  tool "${option}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "scroll-revamped: unknown option '-x'. run 'scroll-revamped help' for usage." ]]
}

@test "commands - --json with any command but list is a usage error" {
  # Arrange
  local flag=--json

  # Act
  tool "${flag}" apply

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "scroll-revamped: option '--json' works only with list. run 'scroll-revamped help' for usage." ]]
}

@test "commands - -- ends the options" {
  # Arrange
  local command=list

  # Act
  tool --theme nord -- "${command}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == set-option\ * ]]
}

@test "commands - an inherited guard variable of the plugin is ignored" {
  # Arrange
  export SCROLL_REVAMPED_SCROLL_LOADED=1 SCROLL_REVAMPED_CORE_LOADED=1

  # Act
  tool version

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" =~ ^scroll-revamped\ [0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "commands - doctor names the clipboard tool drag copy would use" {
  # Arrange
  stub_command wl-copy
  harness_hide pbcopy
  export REVAMPED_TEST_UNAME_S=Linux

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ clipboard\ +ok\ +wl-copy ]]
}

@test "commands - doctor warns when no clipboard tool exists" {
  # Arrange
  harness_hide pbcopy wl-copy xclip xsel

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ clipboard\ +warn\ +drag\ copy\ needs ]]
}

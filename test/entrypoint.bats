#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/tmux_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/tmux_helpers.bash"

bats_require_minimum_version 1.5.0

setup() {
  ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  setup_tmux_server
}

teardown() {
  teardown_tmux_server
}

load_plugin() {
  local quoted
  quoted=$(printf '%s' "$1" | sed "s/'/'\\\\''/g")
  tmux run-shell "'${quoted}/scroll-revamped.tmux'"
}

key_binding() {
  local table
  table=$(tmux list-keys -T "$1")
  awk -v key="$2" '{ for (i = 1; i < NF; i++) { if ($i == "-T") { if ($(i + 2) == key) { print } break } } }' <<<"${table}"
}

check() {
  # shellcheck disable=SC2086
  TMUX="${TMUX_SOCKET},1,0" run ${REVAMPED_TEST_SHELL:-sh} "${ROOT}/bin/scroll-revamped" check "$@"
}

@test "entrypoint - loading turns the mouse on and keeps tmux's wheel by default" {
  # Arrange
  local stock
  stock=$(key_binding root WheelUpPane)

  # Act
  load_plugin "${ROOT}"

  # Assert
  run get_option mouse
  [[ "${output}" == "on" ]]
  run key_binding root WheelUpPane
  [[ "${output}" == "${stock}" ]]
}

@test "entrypoint - the wheel option routes the wheel through one format" {
  # Arrange
  set_option @scroll_revamped_wheel on

  # Act
  load_plugin "${ROOT}"

  # Assert
  run key_binding root WheelUpPane
  [[ "${output}" == *"if-shell -F"*"#{alternate_on}"*"copy-mode -e"* ]]
  run key_binding root WheelDownPane
  [[ "${output}" == *"send-keys -M"* ]]
}

@test "entrypoint - copy-mode options bind both copy-mode tables" {
  # Arrange
  set_option @scroll_revamped_speed 4

  # Act
  load_plugin "${ROOT}"

  # Assert
  run key_binding copy-mode WheelUpPane
  [[ "${output}" == *"send-keys -X -N 4 scroll-up"* ]]
  run key_binding copy-mode-vi WheelDownPane
  [[ "${output}" == *"send-keys -X -N 4 scroll-down"* ]]
}

@test "entrypoint - git tracks the entry point and the tool as executable" {
  # Arrange
  local entry=scroll-revamped.tmux tool=bin/scroll-revamped

  # Act
  run git -C "${ROOT}" ls-files --stage -- "${entry}" "${tool}"

  # Assert
  [[ "${lines[0]}" == 100755\ * ]]
  [[ "${lines[1]}" == 100755\ * ]]
}

@test "check - a decision is stored and a repeat is answered from it" {
  # Arrange
  check 0 0 5 %0

  # Act
  check 0 0 5 %0

  # Assert
  [[ "${status}" -eq 1 ]]
  run get_option @scroll_revamped_cache_key
  [[ "${output}" == "%0|0|0|5" ]]
  run get_option @scroll_revamped_cache_val
  [[ "${output}" == "1" ]]
}

@test "check - the cached tool path survives tmux's parser from a path with a space, a quote and a hash" {
  # Arrange
  local copy="${BATS_TEST_TMPDIR}/it's \"a\" #1 dir" tool
  mkdir -p "${copy}"
  cp -Rf "${ROOT}/bin" "${ROOT}/lib" "${copy}/"
  tool=$(REVAMPED_LIB="${copy}/lib" sh -c '. "${REVAMPED_LIB}/scroll.sh"; scroll_revamped_tool')
  printf 'if-shell "%s check '"'"'1'"'"' '"'"'0'"'"' '"'"''"'"' '"'"'%%0'"'"'" "set -g @probe pass" "set -g @probe copy"\n' "${tool}" >"${BATS_TEST_TMPDIR}/probe.conf"

  # Act
  tmux source-file "${BATS_TEST_TMPDIR}/probe.conf"

  # Assert
  run get_option @probe
  [[ "${output}" == "pass" ]]
  run get_option @scroll_revamped_cache_val
  [[ "${output}" == "0" ]]
}

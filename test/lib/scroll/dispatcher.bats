#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _SCROLL_REVAMPED_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/scroll.sh"
}

teardown() {
  cleanup_test_environment
}

@test "scroll.sh - functions are defined" {
  function_exists scroll_is_passthrough
  function_exists scroll_valid_speed
}

@test "scroll.sh - check passes an alternate-screen pane" {
  run main check 1 0
  [ "${status}" -eq 0 ]
}

@test "scroll.sh - check passes a pane with mouse reporting on" {
  run main check 0 1
  [ "${status}" -eq 0 ]
}

@test "scroll.sh - check enters copy-mode when neither flag is set" {
  run main check 0 0
  [ "${status}" -eq 1 ]
}

@test "scroll.sh - speed echoes a configured throttle" {
  run main speed
  [[ -z "${output}" ]]
  set_tmux_option "@scroll_revamped_speed" "5"
  run main speed
  [[ "${output}" == "5" ]]
  set_tmux_option "@scroll_revamped_speed" "junk"
  run main speed
  [[ -z "${output}" ]]
}

@test "scroll.sh - unknown subcommand produces no output" {
  run main bogus
  [[ -z "${output}" ]]
}

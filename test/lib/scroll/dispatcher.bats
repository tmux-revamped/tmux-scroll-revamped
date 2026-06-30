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
  function_exists scroll_decide
  function_exists scroll_check
  function_exists scroll_valid_speed
}

@test "scroll.sh - check passes an alternate-screen pane" {
  run main check 1 0 "" "%1"
  [ "${status}" -eq 0 ]
}

@test "scroll.sh - check passes a pane with mouse reporting on" {
  run main check 0 1 "" "%1"
  [ "${status}" -eq 0 ]
}

@test "scroll.sh - check enters copy-mode when neither flag is set" {
  run main check 0 0 "" "%1"
  [ "${status}" -eq 1 ]
}

@test "scroll.sh - check passes a pane with no scrollback when skip is active" {
  run main check 0 0 0 "%1"
  [ "${status}" -eq 0 ]
}

@test "scroll.sh - check stores the decision in the cache" {
  main check 0 0 "" "%7" || true
  [[ "$(get_tmux_option @scroll_revamped_cache_key)" == "%7|0|0|" ]]
  [[ "$(get_tmux_option @scroll_revamped_cache_val)" == "1" ]]
}

@test "scroll.sh - check returns the cached decision on a repeat" {
  set_tmux_option "@scroll_revamped_cache_key" "%9|1|0|"
  set_tmux_option "@scroll_revamped_cache_val" "0"
  run main check 1 0 "" "%9"
  [ "${status}" -eq 0 ]
}

@test "scroll.sh - check ignores a corrupt cached value" {
  set_tmux_option "@scroll_revamped_cache_key" "%9|0|0|"
  set_tmux_option "@scroll_revamped_cache_val" "junk"
  run main check 0 0 "" "%9"
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

@test "scroll.sh - runs as a script via the main guard" {
  run bash "${BATS_TEST_DIRNAME}/../../../src/scroll.sh" bogus
  [ "${status}" -eq 0 ]
  [[ -z "${output}" ]]
}

@test "scroll.sh - unknown subcommand produces no output" {
  run main bogus
  [[ -z "${output}" ]]
}

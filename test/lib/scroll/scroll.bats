#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _SCROLL_REVAMPED_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/scroll/scroll.sh"
}

teardown() {
  cleanup_test_environment
}

@test "scroll_is_passthrough passes through an alternate-screen pane" {
  run scroll_is_passthrough "1" "0"
  [ "${status}" -eq 0 ]
}

@test "scroll_is_passthrough passes through a pane that requested mouse reporting" {
  run scroll_is_passthrough "0" "1"
  [ "${status}" -eq 0 ]
}

@test "scroll_is_passthrough enters copy-mode when neither flag is set" {
  run scroll_is_passthrough "0" "0"
  [ "${status}" -eq 1 ]
  run scroll_is_passthrough "" ""
  [ "${status}" -eq 1 ]
}

@test "scroll_decide passes through on alternate, mouse, or empty scrollback" {
  run scroll_decide "1" "0" ""
  [ "${status}" -eq 0 ]
  run scroll_decide "0" "1" ""
  [ "${status}" -eq 0 ]
  run scroll_decide "0" "0" "0"
  [ "${status}" -eq 0 ]
}

@test "scroll_decide enters copy-mode with scrollback and no app flags" {
  run scroll_decide "0" "0" "1500"
  [ "${status}" -eq 1 ]
  run scroll_decide "0" "0" ""
  [ "${status}" -eq 1 ]
}

@test "scroll_cache_key is stable for the same inputs" {
  local a b
  a="$(scroll_cache_key 1 0 "" "%3")"
  b="$(scroll_cache_key 1 0 "" "%3")"
  [[ "${a}" == "${b}" ]]
  [[ "${a}" == "%3|1|0|" ]]
}

@test "scroll_cache_key changes when the pane or flags change" {
  [[ "$(scroll_cache_key 1 0 "" "%3")" != "$(scroll_cache_key 0 0 "" "%3")" ]]
  [[ "$(scroll_cache_key 1 0 "" "%3")" != "$(scroll_cache_key 1 0 "" "%4")" ]]
}

@test "scroll_valid_speed accepts positive integers only" {
  [[ "$(scroll_valid_speed 3)" == "3" ]]
  [[ "$(scroll_valid_speed 12)" == "12" ]]
  [[ -z "$(scroll_valid_speed 0)" ]]
  [[ -z "$(scroll_valid_speed -2)" ]]
  [[ -z "$(scroll_valid_speed abc)" ]]
  [[ -z "$(scroll_valid_speed "")" ]]
}

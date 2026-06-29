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

@test "scroll_valid_speed accepts positive integers only" {
  [[ "$(scroll_valid_speed 3)" == "3" ]]
  [[ "$(scroll_valid_speed 12)" == "12" ]]
  [[ -z "$(scroll_valid_speed 0)" ]]
  [[ -z "$(scroll_valid_speed -2)" ]]
  [[ -z "$(scroll_valid_speed abc)" ]]
  [[ -z "$(scroll_valid_speed "")" ]]
}

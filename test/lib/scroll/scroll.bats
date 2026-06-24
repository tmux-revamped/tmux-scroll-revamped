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

@test "scroll_build_pattern builds an anchored alternation" {
  [[ "$(scroll_build_pattern "vim less")" == '^(vim|less)$' ]]
}

@test "scroll_build_pattern de-duplicates and normalizes separators" {
  [[ "$(scroll_build_pattern "vim, vim  less")" == '^(vim|less)$' ]]
}

@test "scroll_build_pattern with empty input matches nothing" {
  [[ "$(scroll_build_pattern "")" == '$^' ]]
}

@test "scroll_is_passthrough recognizes membership" {
  run scroll_is_passthrough "vim" "vim less man"
  [ "${status}" -eq 0 ]
  run scroll_is_passthrough "ssh" "vim less man"
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

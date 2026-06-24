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
  function_exists scroll_build_pattern
  function_exists scroll_apps
}

@test "scroll.sh - pattern emits a regex including the default apps" {
  run main pattern
  [[ "${output}" == '^('*'vim'*')$' ]]
  [[ "${output}" == *'less'* ]]
}

@test "scroll.sh - check passes known apps and rejects others" {
  run main check vim
  [ "${status}" -eq 0 ]
  run main check ssh
  [ "${status}" -eq 1 ]
}

@test "scroll.sh - the passthrough list is configurable" {
  set_tmux_option "@scroll_revamped_passthrough_apps" "foo bar"
  run main check foo
  [ "${status}" -eq 0 ]
  run main check vim
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

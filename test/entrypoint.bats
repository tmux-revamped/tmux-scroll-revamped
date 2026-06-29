#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/tmux_helpers.bash"

setup() {
  setup_tmux_server
}

teardown() {
  teardown_tmux_server
}

# wheel_binding -> the generated root-table WheelUpPane binding.
wheel_binding() {
  tmux list-keys 2>/dev/null | grep WheelUpPane | grep root
}

# tmux_ge VER -> exit 0 when the running tmux is at least VER.
tmux_ge() {
  local have
  have="$(command tmux -V | sed -E 's/^tmux ([0-9]+\.[0-9]+).*/\1/')"
  [[ "$(printf '%s\n%s\n' "${1}" "${have}" | sort -V | head -n1)" == "${1}" ]]
}

@test "entrypoint - alternate-screen apps get the wheel by default" {
  tmux_ge "3.1" || skip "native routing needs tmux 3.1+"
  tmux run-shell "${PLUGIN_DIR}/scroll-revamped.tmux"
  run wheel_binding
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"alternate_on"* ]]
}

@test "entrypoint - passthrough_alternate off drops the alternate-screen term" {
  tmux_ge "3.1" || skip "native routing needs tmux 3.1+"
  tmux set-option -g @scroll_revamped_passthrough_alternate off
  tmux run-shell "${PLUGIN_DIR}/scroll-revamped.tmux"
  run wheel_binding
  [ "${status}" -eq 0 ]
  [[ "${output}" != *"alternate_on"* ]]
  [[ "${output}" == *"mouse_any_flag"* ]]
}

@test "entrypoint - apps with mouse reporting get the wheel by default" {
  tmux_ge "3.1" || skip "native routing needs tmux 3.1+"
  tmux run-shell "${PLUGIN_DIR}/scroll-revamped.tmux"
  run wheel_binding
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"mouse_any_flag"* ]]
}

@test "entrypoint - passthrough_mouse off drops the mouse-flag term" {
  tmux_ge "3.1" || skip "native routing needs tmux 3.1+"
  tmux set-option -g @scroll_revamped_passthrough_mouse off
  tmux run-shell "${PLUGIN_DIR}/scroll-revamped.tmux"
  run wheel_binding
  [ "${status}" -eq 0 ]
  [[ "${output}" != *"mouse_any_flag"* ]]
}

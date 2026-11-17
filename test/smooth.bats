#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/wheel_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/wheel_helpers.bash"

bats_require_minimum_version 1.5.0

ticks() {
  local count="$1"
  while ((count > 0)); do
    wheel "$2" "$3" "$4"
    count=$((count - 1))
  done
}

errors() {
  local log
  log=$(tmux show-messages)
  grep -c ' message: ' <<<"${log}" || :
}

@test "smooth - a tick up over a shell enters copy-mode and ends five lines up" {
  # Arrange
  setting wheel on
  setting smooth on
  load_plugin
  history %0

  # Act
  wheel "${UP}" 10 5

  # Assert
  wait_for shows %0 '#{pane_in_mode} #{scroll_position}' '1 5'
}

@test "smooth - the speed sets how many lines a tick ends up scrolling" {
  # Arrange
  setting wheel on
  setting smooth on
  setting speed 7
  load_plugin
  history %0

  # Act
  wheel "${UP}" 10 5

  # Assert
  wait_for shows %0 '#{pane_in_mode} #{scroll_position}' '1 7'
}

@test "smooth - a speed above twenty lines still scrolls every line" {
  # Arrange
  setting wheel on
  setting smooth on
  setting speed 23
  load_plugin
  history %0

  # Act
  wheel "${UP}" 10 5

  # Assert
  wait_for shows %0 '#{pane_in_mode} #{scroll_position}' '1 23'
}

@test "smooth - three ticks sent one after another scroll every line of each" {
  # Arrange
  setting wheel on
  setting smooth on
  load_plugin
  history %0

  # Act
  ticks 3 "${UP}" 10 5

  # Assert
  wait_for shows %0 '#{pane_in_mode} #{scroll_position}' '1 15'
}

@test "smooth - a tick down in copy-mode scrolls back by the same lines" {
  # Arrange
  setting wheel on
  setting smooth on
  load_plugin
  history %0
  wheel "${UP}" 10 5
  wait_for shows %0 '#{scroll_position}' 5
  wheel "${UP}" 10 5
  wait_for shows %0 '#{scroll_position}' 10

  # Act
  wheel "${DOWN}" 10 5

  # Assert
  wait_for shows %0 '#{pane_in_mode} #{scroll_position}' '1 5'
}

@test "smooth - a tick down that reaches the bottom leaves copy-mode and shows no error" {
  # Arrange
  setting wheel on
  setting smooth on
  load_plugin
  history %0
  wheel "${UP}" 10 5
  wait_for shows %0 '#{scroll_position}' 5
  tmux send-keys -t %0 -X -N 3 scroll-down
  wait_for shows %0 '#{scroll_position}' 2
  tmux bind-key -n F9 set-option -g @smooth_done 1

  # Act
  wheel "${DOWN}" 10 5

  # Assert
  wait_for shows %0 '#{pane_in_mode}' 0
  command tmux -S "${HOST}" send-keys -t host F9
  wait_for shows test: '#{@smooth_done}' 1
  run errors
  [[ "${output}" == 0 ]]
}

@test "smooth - with auto exit, a tick down at the bottom leaves copy-mode" {
  # Arrange
  setting wheel on
  setting smooth on
  setting auto_exit on
  load_plugin
  history %0
  tmux copy-mode -t %0
  wait_for shows %0 '#{pane_in_mode} #{scroll_position}' '1 0'

  # Act
  wheel "${DOWN}" 10 5

  # Assert
  wait_for shows %0 '#{pane_in_mode}' 0
}

@test "smooth - a tick over a pane that is not the active one scrolls the pane under the pointer" {
  # Arrange
  setting wheel on
  setting smooth on
  load_plugin
  tmux split-window -h -t test
  history %1
  tmux select-pane -t %0

  # Act
  wheel "${UP}" 80 5

  # Assert
  wait_for shows %1 '#{pane_in_mode} #{scroll_position}' '1 5'
  wait_for shows %0 '#{pane_in_mode}' 0
}

#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/wheel_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/wheel_helpers.bash"

bats_require_minimum_version 1.5.0

@test "wheel - with the wheel option, a tick up over a shell with history enters copy-mode and scrolls tmux's five lines" {
  # Arrange
  setting wheel on
  load_plugin
  history %0

  # Act
  wheel "${UP}" 10 5

  # Assert
  wait_for shows %0 '#{pane_in_mode} #{scroll_position}' '1 5'
}

@test "wheel - a tick over an app on the alternate screen stays out of copy-mode and leaves the keys to the app" {
  # Arrange
  setting wheel on
  load_plugin
  reads %0 alt
  wait_for shows %0 '#{alternate_on}' 1

  # Act
  wheel "${UP}" 10 5

  # Assert
  command tmux -S "${HOST}" send-keys -t host x
  wait_for pane_shows %0 ' 78'
  wait_for shows %0 '#{pane_in_mode}' 0
}

@test "wheel - with alternate passthrough off, a tick over an alternate-screen app enters copy-mode" {
  # Arrange
  setting wheel on
  setting passthrough_alternate off
  load_plugin
  reads %0 alt
  wait_for shows %0 '#{alternate_on}' 1

  # Act
  wheel "${UP}" 10 5

  # Assert
  wait_for shows %0 '#{pane_in_mode}' 1
}

@test "wheel - a tick over an app that asked for the mouse reaches the app as a mouse event" {
  # Arrange
  setting wheel on
  load_plugin
  reads %0 mouse
  wait_for shows %0 '#{mouse_any_flag}' 1

  # Act
  wheel "${UP}" 10 5

  # Assert
  wait_for pane_shows %0 ' 3c'
  wait_for shows %0 '#{pane_in_mode}' 0
}

@test "wheel - with mouse passthrough off, a tick over an app that asked for the mouse enters copy-mode" {
  # Arrange
  setting wheel on
  setting passthrough_mouse off
  load_plugin
  reads %0 mouse
  wait_for shows %0 '#{mouse_any_flag}' 1

  # Act
  wheel "${UP}" 10 5

  # Assert
  wait_for shows %0 '#{pane_in_mode}' 1
}

@test "wheel - a tick over a pane with no history enters copy-mode by default" {
  # Arrange
  setting wheel on
  load_plugin
  tmux clear-history -t %0

  # Act
  wheel "${UP}" 10 5

  # Assert
  wait_for shows %0 '#{pane_in_mode}' 1
}

@test "wheel - with skip empty, a tick over a pane with no history stays out of copy-mode" {
  # Arrange
  setting wheel on
  setting skip_empty on
  load_plugin
  tmux clear-history -t %0

  # Act
  wheel "${UP}" 10 5

  # Assert
  command tmux -S "${HOST}" send-keys -t host "echo ty''ped" Enter
  wait_for pane_shows %0 $'\ntyped'
  wait_for shows %0 '#{pane_in_mode}' 0
}

@test "wheel - with select pane, a tick over another pane focuses it first" {
  # Arrange
  setting wheel on
  setting select_pane on
  load_plugin
  tmux split-window -h -t test
  tmux select-pane -t %0
  history %1

  # Act
  wheel "${UP}" 80 5

  # Assert
  wait_for shows test: '#{pane_id}' %1
  wait_for shows %1 '#{pane_in_mode}' 1
}

@test "wheel - arrow keys: a tick up over an alternate-screen app with the mouse off sends three Up keys" {
  # Arrange
  setting wheel on
  setting alt_keys arrow
  load_plugin
  reads %0 alt
  wait_for shows %0 '#{alternate_on}' 1

  # Act
  wheel "${UP}" 10 5

  # Assert
  wait_for pane_counts %0 ' 41$' 3
}

@test "wheel - arrow keys: the speed sets how many Down keys a tick down sends" {
  # Arrange
  setting wheel on
  setting alt_keys arrow
  setting speed 5
  load_plugin
  reads %0 alt
  wait_for shows %0 '#{alternate_on}' 1

  # Act
  wheel "${DOWN}" 10 5

  # Assert
  wait_for pane_counts %0 ' 42$' 5
}

@test "wheel - page keys: a tick up over an alternate-screen app sends one PageUp" {
  # Arrange
  setting wheel on
  setting alt_keys page
  load_plugin
  reads %0 alt
  wait_for shows %0 '#{alternate_on}' 1

  # Act
  wheel "${UP}" 10 5

  # Assert
  wait_for pane_counts %0 ' 7e$' 1
  wait_for pane_counts %0 ' 35$' 1
}

@test "wheel - page keys: a tick down over an alternate-screen app sends one PageDown" {
  # Arrange
  setting wheel on
  setting alt_keys page
  load_plugin
  reads %0 alt
  wait_for shows %0 '#{alternate_on}' 1

  # Act
  wheel "${DOWN}" 10 5

  # Assert
  wait_for pane_counts %0 ' 7e$' 1
  wait_for pane_counts %0 ' 36$' 1
}

@test "wheel - the speed sets how many lines a copy-mode tick scrolls" {
  # Arrange
  setting wheel on
  setting speed 7
  load_plugin
  history %0

  # Act
  wheel "${UP}" 10 5

  # Assert
  wait_for shows %0 '#{pane_in_mode} #{scroll_position}' '1 7'
}

@test "wheel - a tick down in copy-mode scrolls back by the speed" {
  # Arrange
  setting wheel on
  setting speed 7
  load_plugin
  history %0
  wheel "${UP}" 10 5
  wait_for shows %0 '#{scroll_position}' 7
  wheel "${UP}" 10 5
  wait_for shows %0 '#{scroll_position}' 14

  # Act
  wheel "${DOWN}" 10 5

  # Assert
  wait_for shows %0 '#{pane_in_mode} #{scroll_position}' '1 7'
}

@test "wheel - half-page granularity scrolls half the pane per tick" {
  # Arrange
  setting wheel on
  setting granularity halfpage
  load_plugin
  history %0

  # Act
  wheel "${UP}" 10 5

  # Assert
  wait_for shows %0 '#{pane_in_mode} #{scroll_position}' '1 14'
}

@test "wheel - page granularity scrolls a page per tick" {
  # Arrange
  setting wheel on
  setting granularity page
  load_plugin
  history %0

  # Act
  wheel "${UP}" 10 5

  # Assert
  wait_for shows %0 '#{pane_in_mode} #{scroll_position}' '1 27'
}

@test "wheel - with auto exit, a tick down at the bottom leaves copy-mode" {
  # Arrange
  setting wheel on
  setting speed 4
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

@test "wheel - with auto exit, a tick down above the bottom scrolls and stays in copy-mode" {
  # Arrange
  setting wheel on
  setting speed 4
  setting auto_exit on
  load_plugin
  history %0
  wheel "${UP}" 10 5
  wait_for shows %0 '#{scroll_position}' 4
  wheel "${UP}" 10 5
  wait_for shows %0 '#{scroll_position}' 8

  # Act
  wheel "${DOWN}" 10 5

  # Assert
  wait_for shows %0 '#{pane_in_mode} #{scroll_position}' '1 4'
}

@test "wheel - the indicator flashes the scroll position on a copy-mode tick" {
  # Arrange
  setting wheel on
  setting speed 6
  setting indicator on
  load_plugin
  history %0

  # Act
  wheel "${UP}" 10 5

  # Assert
  wait_for host_shows 'scroll 6/'
}

@test "wheel - drag copy sends a mouse selection in copy-mode to the clipboard tool" {
  # Arrange
  setting wheel on
  setting drag_copy on
  load_plugin
  tmux send-keys -t %0 "echo clip''board-text" Enter
  wait_for pane_shows %0 $'\nclipboard-text'
  tmux copy-mode -t %0
  wait_for shows %0 '#{pane_in_mode}' 1

  # Act
  command tmux -S "${HOST}" send-keys -t host -l $'\e[<0;1;2M\e[<32;5;2M\e[<32;15;2M\e[<0;15;2m'

  # Assert
  wait_for file_holds "${BATS_TEST_TMPDIR}/clipboard" 'clipboard-text'
  wait_for shows %0 '#{pane_in_mode}' 0
}

@test "wheel - with the status wheel, a tick down over the status line goes to the next window" {
  # Arrange
  setting status_wheel on
  load_plugin
  tmux new-window -d -t test:

  # Act
  wheel "${DOWN}" 10 "${STATUS_ROW}"

  # Assert
  wait_for shows test: '#{window_index}' 1
}

@test "wheel - with the status wheel, a tick up over the status line goes to the previous window" {
  # Arrange
  setting status_wheel on
  load_plugin
  tmux new-window -t test:

  # Act
  wheel "${UP}" 10 "${STATUS_ROW}"

  # Assert
  wait_for shows test: '#{window_index}' 0
}

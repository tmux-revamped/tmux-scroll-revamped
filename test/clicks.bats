#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/wheel_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/wheel_helpers.bash"

bats_require_minimum_version 1.5.0

@test "clicks - a double click sends the word under the pointer to the clipboard tool and leaves copy-mode" {
  # Arrange
  setting click_copy on
  load_plugin
  words %0

  # Act
  clicks 2 8 2

  # Assert
  wait_for file_is "${BATS_TEST_TMPDIR}/clipboard" beta
  wait_for shows %0 '#{pane_in_mode}' 0
}

@test "clicks - a triple click sends the line under the pointer to the clipboard tool" {
  # Arrange
  setting click_copy on
  load_plugin
  words %0

  # Act
  clicks 3 8 2

  # Assert
  wait_for file_is "${BATS_TEST_TMPDIR}/clipboard" 'alpha beta gamma'
  wait_for shows %0 '#{pane_in_mode}' 0
}

@test "clicks - a double click inside copy-mode copies the word and leaves the mode" {
  # Arrange
  setting click_copy on
  load_plugin
  words %0
  tmux copy-mode -t %0
  wait_for shows %0 '#{pane_in_mode}' 1

  # Act
  clicks 2 8 2

  # Assert
  wait_for file_is "${BATS_TEST_TMPDIR}/clipboard" beta
  wait_for shows %0 '#{pane_in_mode}' 0
}

@test "clicks - a double click over an app that asked for the mouse reaches the app" {
  # Arrange
  setting click_copy on
  load_plugin
  reads %0 mouse
  wait_for shows %0 '#{mouse_any_flag}' 1

  # Act
  clicks 2 8 2

  # Assert
  wait_for pane_shows %0 ' 3c'
  wait_for shows %0 '#{pane_in_mode}' 0
}

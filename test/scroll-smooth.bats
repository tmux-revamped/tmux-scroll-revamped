#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034

# shellcheck source=test/scroll_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/scroll_helpers.bash"

pauses() {
  local rest="${1//run-shell -d 0.005/}"
  echo $(((${#1} - ${#rest}) / 18))
}

@test "scroll - smooth: a tick is tmux's five lines, one at a time with a pause between" {
  # Arrange
  option smooth on
  option mouse off

  # Act
  plan_at 3.6

  # Assert
  [[ "${lines[0]}" == "bind-key -T copy-mode WheelUpPane send-keys -X -N 1 scroll-up ; run-shell -d 0.005 ; send-keys -X -N 1 scroll-up ; run-shell -d 0.005 ; send-keys -X -N 1 scroll-up ; run-shell -d 0.005 ; send-keys -X -N 1 scroll-up ; run-shell -d 0.005 ; send-keys -X -N 1 scroll-up" ]] || false
  [[ "${lines[2]}" == "bind-key -T copy-mode-vi WheelUpPane ${lines[0]#bind-key -T copy-mode WheelUpPane }" ]] || false
  [[ "${#lines[@]}" -eq 4 ]]
}

@test "scroll - smooth: every step down after the first runs only while the pane is still in copy-mode" {
  # Arrange
  option smooth on
  option speed 2
  option mouse off

  # Act
  plan_at 3.6

  # Assert
  [[ "${lines[1]}" == 'bind-key -T copy-mode WheelDownPane send-keys -X -N 1 scroll-down ; run-shell -d 0.005 ; if-shell -F "#{pane_in_mode}" "send-keys -X -N 1 scroll-down"' ]] || false
  [[ "${lines[3]}" == 'bind-key -T copy-mode-vi WheelDownPane send-keys -X -N 1 scroll-down ; run-shell -d 0.005 ; if-shell -F "#{pane_in_mode}" "send-keys -X -N 1 scroll-down"' ]]
}

@test "scroll - smooth: the speed sets the number of steps" {
  # Arrange
  option smooth on
  option speed 3
  option mouse off

  # Act
  plan_at 3.6

  # Assert
  [[ "${lines[0]}" == "bind-key -T copy-mode WheelUpPane send-keys -X -N 1 scroll-up ; run-shell -d 0.005 ; send-keys -X -N 1 scroll-up ; run-shell -d 0.005 ; send-keys -X -N 1 scroll-up" ]]
}

@test "scroll - smooth: a speed of one line is a single step with no pause" {
  # Arrange
  option smooth on
  option speed 1
  option mouse off

  # Act
  plan_at 3.6

  # Assert
  [[ "${lines[0]}" == "bind-key -T copy-mode WheelUpPane send-keys -X -N 1 scroll-up" ]]
}

@test "scroll - smooth: above twenty lines the steps stay at twenty and the first carries the remainder" {
  # Arrange
  option smooth on
  option speed 45
  option mouse off

  # Act
  plan_at 3.6

  # Assert
  [[ "${lines[0]}" == "bind-key -T copy-mode WheelUpPane send-keys -X -N 7 scroll-up ; run-shell -d 0.005 ; send-keys -X -N 2 scroll-up ; "* ]] || false
  [[ "${lines[0]}" == *" ; run-shell -d 0.005 ; send-keys -X -N 2 scroll-up" ]] || false
  run pauses "${lines[0]}"
  [[ "${output}" == 19 ]]
}

@test "scroll - smooth: a speed of a thousand lines or more scrolls in one step" {
  # Arrange
  option smooth on
  option speed 1000
  option mouse off

  # Act
  plan_at 3.6

  # Assert
  [[ "${lines[0]}" == "bind-key -T copy-mode WheelUpPane send-keys -X -N 1000 scroll-up" ]]
}

@test "scroll - smooth: page granularity scrolls a whole page in one step" {
  # Arrange
  option smooth on
  option granularity page
  option mouse off

  # Act
  plan_at 3.6

  # Assert
  [[ "${lines[0]}" == "bind-key -T copy-mode WheelUpPane send-keys -X page-up" ]]
}

@test "scroll - smooth: before tmux 3.2 it binds nothing" {
  # Arrange
  option smooth on
  option mouse off

  # Act
  plan_at 3.1

  # Assert
  [[ -z "${output}" ]]
}

@test "scroll - smooth: with the wheel routing, the tick that enters copy-mode scrolls in steps too" {
  # Arrange
  option smooth on
  option speed 2
  option wheel on
  option mouse off

  # Act
  plan_at 3.6

  # Assert
  [[ "${lines[0]}" == 'bind-key -n WheelUpPane if-shell -F "#{?#{||:#{alternate_on},#{||:#{mouse_any_flag},#{pane_in_mode}}},1,0}" "send-keys -M" "copy-mode -e ; send-keys -X -N 1 scroll-up ; run-shell -d 0.005 ; send-keys -X -N 1 scroll-up"' ]]
}

@test "scroll - smooth: with auto exit, the steps down run only above the bottom" {
  # Arrange
  option smooth on
  option speed 2
  option auto_exit on
  option mouse off

  # Act
  plan_at 3.6

  # Assert
  [[ "${lines[1]}" == "bind-key -T copy-mode WheelDownPane if-shell -F '#{?#{==:#{scroll_position},0},1,0}' 'send-keys -X cancel' 'send-keys -X -N 1 scroll-down ; run-shell -d 0.005 ; if-shell -F \"#{pane_in_mode}\" \"send-keys -X -N 1 scroll-down\"'" ]]
}

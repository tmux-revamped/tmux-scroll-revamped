#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/tmux_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/tmux_helpers.bash"

bats_require_minimum_version 1.5.0

UP=64
DOWN=65
STATUS_ROW=30

screens() {
  printf 'host screen:\n'
  command tmux -S "${HOST}" capture-pane -p -t host || :
  printf 'panes:\n'
  tmux list-panes -a -F '#{window_index} #{pane_id} active=#{pane_active} mode=#{pane_in_mode} at=#{scroll_position} history=#{history_size} alt=#{alternate_on} mouse=#{mouse_any_flag}' || :
}

wait_for() {
  local delay
  for delay in 0.01 0.02 0.05 0.1 0.1 0.2 0.2 0.5 0.5 1 1 1 2 2; do
    "$@" && return 0
    sleep "${delay}"
  done
  "$@" && return 0
  screens
  return 1
}

attached() {
  local clients
  clients=$(tmux list-clients -F x 2>/dev/null)
  [[ -n "${clients}" ]]
}

shows() {
  local now
  now=$(tmux display-message -p -t "$1" "$2" 2>/dev/null)
  [[ "${now}" == "$3" ]]
}

host_shows() {
  local screen
  screen=$(command tmux -S "${HOST}" capture-pane -p -t host)
  [[ "${screen}" == *"$1"* ]]
}

pane_shows() {
  local screen
  screen=$(tmux capture-pane -p -t "$1")
  [[ "${screen}" == *"$2"* ]]
}

pane_counts() {
  local screen count
  screen=$(tmux capture-pane -p -t "$1")
  count=$(grep -c -- "$2" <<<"${screen}")
  [[ "${count}" == "$3" ]]
}

file_holds() {
  [[ -f "$1" ]] || return 1
  grep -qF -- "$2" "$1"
}

setup() {
  ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  STUBS="${BATS_TEST_TMPDIR}/stubs"
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "${HOME}" "${STUBS}"
  cat >"${STUBS}/reader" <<'READER'
#!/bin/sh
for mode in "$@"; do
  case "${mode}" in
  alt) printf '\033[?1049h' ;;
  mouse) printf '\033[?1000h\033[?1006h' ;;
  *) : ;;
  esac
done
stty -icanon -isig -echo
echo ready
while :; do dd bs=1 count=1 2>/dev/null | od -An -tx1; done
READER
  printf '#!/bin/sh\ncat >"%s"\n' "${BATS_TEST_TMPDIR}/clipboard" >"${STUBS}/pbcopy"
  cp -f "${STUBS}/pbcopy" "${STUBS}/wl-copy"
  chmod +x "${STUBS}/reader" "${STUBS}/pbcopy" "${STUBS}/wl-copy"
  PATH="${STUBS}:${PATH}"
  setup_tmux_server
  HOST="${TMUX_SOCKET}-host"
  tmux set-option -g default-command "env PS1='$ ' sh"
  tmux respawn-pane -k -t test:0.0 "env PS1='$ ' sh"
  command tmux -S "${HOST}" -f /dev/null new-session -d -s host -x 100 -y "${STATUS_ROW}" \
    "env -u TMUX TERM=xterm-256color tmux -S '${TMUX_SOCKET}' attach-session -t test"
  wait_for attached
  wait_for shows test: '#{window_width}x#{window_height}' 100x29
}

teardown() {
  command tmux -S "${HOST}" kill-server 2>/dev/null || :
  rm -f "${HOST}"
  teardown_tmux_server
}

load_plugin() {
  local quoted
  quoted=$(printf '%s' "${ROOT}" | sed "s/'/'\\\\''/g")
  tmux run-shell "'${quoted}/scroll-revamped.tmux'"
}

setting() {
  set_option "@scroll_revamped_$1" "$2"
}

history() {
  tmux send-keys -t "$1" 'i=0; while [ $i -lt 120 ]; do echo row$i; i=$((i+1)); done' Enter
  wait_for pane_shows "$1" row119
}

reads() {
  local pane="$1"
  shift
  tmux respawn-pane -k -t "${pane}" "sh '${STUBS}/reader' $*"
  wait_for pane_shows "${pane}" ready
}

wheel() {
  command tmux -S "${HOST}" send-keys -t host -l $'\e[<'"$1;$2;$3M"
}

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

#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/tmux_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/tmux_helpers.bash"

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

file_is() {
  local now
  [[ -f "$1" ]] || return 1
  now=$(cat "$1")
  [[ "${now}" == "$2" ]]
}

clicks() {
  local count="$1" press release
  press=$'\e[<0;'"$2;$3M"
  release=$'\e[<0;'"$2;$3m"
  while ((count > 0)); do
    command tmux -S "${HOST}" send-keys -t host -l "${press}"
    command tmux -S "${HOST}" send-keys -t host -l "${release}"
    count=$((count - 1))
  done
}

words() {
  tmux send-keys -t "$1" "echo alpha be''ta gamma" Enter
  wait_for pane_shows "$1" $'\nalpha beta gamma'
}

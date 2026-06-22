#!/usr/bin/env bash
#
# scroll.sh: command dispatcher for tmux-scroll-revamped.
#
# Usage: scroll.sh pattern | check <command>
#
# pattern prints the regex the fast tmux-native binding embeds. check is the
# fallback used by older tmux without regex match: exit 0 when the foreground
# command should receive the wheel directly, exit 1 to enter copy-mode.

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/tmux/tmux-ops.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/scroll/scroll.sh"

# Default passthrough apps: full-screen programs that handle their own scrolling.
scroll_apps() {
  get_tmux_option "@scroll_revamped_passthrough_apps" \
    "vim nvim view vimdiff emacs nano less more man git tig bat htop btop top atop glances nvtop watch fzf lazygit gitui ranger nnn lf mc weechat irssi mutt neomutt w3m lynx"
}

main() {
  case "${1:-}" in
    pattern) scroll_build_pattern "$(scroll_apps)" ;;
    check)   scroll_is_passthrough "${2:-}" "$(scroll_apps)" ;;
    *)       return 0 ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

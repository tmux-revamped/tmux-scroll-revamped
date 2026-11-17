# shellcheck shell=bash
# shellcheck disable=SC2207

_scroll_revamped() {
  local cur prev
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"

  case "${prev}" in
  --theme)
    COMPREPLY=($(compgen -W "kodougu catppuccin-mocha catppuccin-latte dracula nord gruvbox tokyo-night mono" -- "${cur}"))
    return
    ;;
  --wheel)
    COMPREPLY=($(compgen -W "on off" -- "${cur}"))
    return
    ;;
  --passthrough-alternate)
    COMPREPLY=($(compgen -W "on off" -- "${cur}"))
    return
    ;;
  --passthrough-mouse)
    COMPREPLY=($(compgen -W "on off" -- "${cur}"))
    return
    ;;
  --skip-empty)
    COMPREPLY=($(compgen -W "on off" -- "${cur}"))
    return
    ;;
  --select-pane)
    COMPREPLY=($(compgen -W "on off" -- "${cur}"))
    return
    ;;
  --alt-keys)
    COMPREPLY=($(compgen -W "arrow page" -- "${cur}"))
    return
    ;;
  --mouse)
    COMPREPLY=($(compgen -W "on off" -- "${cur}"))
    return
    ;;
  --granularity)
    COMPREPLY=($(compgen -W "line halfpage page" -- "${cur}"))
    return
    ;;
  --auto-exit)
    COMPREPLY=($(compgen -W "on off" -- "${cur}"))
    return
    ;;
  --indicator)
    COMPREPLY=($(compgen -W "on off" -- "${cur}"))
    return
    ;;
  --drag-copy)
    COMPREPLY=($(compgen -W "on off" -- "${cur}"))
    return
    ;;
  --click-copy)
    COMPREPLY=($(compgen -W "on off" -- "${cur}"))
    return
    ;;
  --smooth)
    COMPREPLY=($(compgen -W "on off" -- "${cur}"))
    return
    ;;
  --status-wheel)
    COMPREPLY=($(compgen -W "on off" -- "${cur}"))
    return
    ;;
  --speed)
    return
    ;;
  *) ;;
  esac

  COMPREPLY=($(compgen -W "apply list check doctor version help --json --theme --wheel --passthrough-alternate --passthrough-mouse --skip-empty --select-pane --alt-keys --mouse --speed --granularity --auto-exit --indicator --drag-copy --click-copy --smooth --status-wheel" -- "${cur}"))
}

complete -F _scroll_revamped scroll-revamped

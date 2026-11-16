export PS1='$ '
export PATH="${SCREENS_REPO:?}/bin:${PATH}"
unset KODOUGU_THEME KODOUGU_ACCENT SCROLL_REVAMPED_THEME SCROLL_REVAMPED_ACCENT NO_COLOR
export HOME=/Users/Shared/demo/home
cd /Users/Shared/demo || return 1
printf '\033]2;demo\033\134'
clear

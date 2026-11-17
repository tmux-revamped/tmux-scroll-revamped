Source common.tape
Output hero.gif
Hide
Type "tmux -L revamped-screens attach -t demo"
Enter
Sleep 2s
Type "tmux rename-window shell; tmux new-window -d -n notes; seq -f 'line %g of the build log' 1 200"
Enter
Sleep 1s
Show
Sleep 800ms
Hide
Ctrl+]
Type@5ms "Mouse wheel up"
Enter
Show
Escape
Type@1ms "[<64;40;12M"
Sleep 150ms
Escape
Type@1ms "[<64;40;12M"
Sleep 150ms
Escape
Type@1ms "[<64;40;12M"
Sleep 150ms
Escape
Type@1ms "[<64;40;12M"
Sleep 150ms
Escape
Type@1ms "[<64;40;12M"
Sleep 150ms
Escape
Type@1ms "[<64;40;12M"
Sleep 150ms
Escape
Type@1ms "[<64;40;12M"
Sleep 150ms
Escape
Type@1ms "[<64;40;12M"
Sleep 150ms
Sleep 800ms
Screenshot wheel-shell.png
Sleep 500ms
Hide
Ctrl+]
Type@5ms "Mouse wheel down"
Enter
Show
Escape
Type@1ms "[<65;40;12M"
Sleep 150ms
Escape
Type@1ms "[<65;40;12M"
Sleep 150ms
Escape
Type@1ms "[<65;40;12M"
Sleep 150ms
Escape
Type@1ms "[<65;40;12M"
Sleep 150ms
Escape
Type@1ms "[<65;40;12M"
Sleep 150ms
Escape
Type@1ms "[<65;40;12M"
Sleep 150ms
Escape
Type@1ms "[<65;40;12M"
Sleep 150ms
Escape
Type@1ms "[<65;40;12M"
Sleep 150ms
Sleep 1s
Hide
Ctrl+]
Type@5ms "tmux set -g @scroll_revamped_alt_keys arrow; scroll-revamped apply"
Enter
Show
Type "tmux set -g @scroll_revamped_alt_keys arrow; scroll-revamped apply"
Sleep 400ms
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1s
Hide
Ctrl+]
Type@5ms "seq -f 'page line %g' 1 200 | less"
Enter
Show
Type "seq -f 'page line %g' 1 200 | less"
Sleep 400ms
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1500ms
Hide
Ctrl+]
Type@5ms "Mouse wheel down"
Enter
Show
Escape
Type@1ms "[<65;40;12M"
Sleep 150ms
Escape
Type@1ms "[<65;40;12M"
Sleep 150ms
Escape
Type@1ms "[<65;40;12M"
Sleep 150ms
Escape
Type@1ms "[<65;40;12M"
Sleep 150ms
Escape
Type@1ms "[<65;40;12M"
Sleep 150ms
Escape
Type@1ms "[<65;40;12M"
Sleep 150ms
Sleep 800ms
Screenshot wheel-less.png
Sleep 500ms
Hide
Ctrl+]
Type@5ms "q"
Enter
Show
Type "q"
Sleep 800ms
Hide
Type "clear"
Enter
Show
Hide
Ctrl+]
Type@5ms "tmux set -g @scroll_revamped_indicator on; scroll-revamped apply"
Enter
Show
Type "tmux set -g @scroll_revamped_indicator on; scroll-revamped apply"
Sleep 400ms
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1s
Hide
Type "seq 1 200"
Enter
Sleep 500ms
Show
Hide
Ctrl+]
Type@5ms "Mouse wheel up"
Enter
Show
Escape
Type@1ms "[<64;40;12M"
Sleep 150ms
Escape
Type@1ms "[<64;40;12M"
Sleep 150ms
Escape
Type@1ms "[<64;40;12M"
Sleep 150ms
Escape
Type@1ms "[<64;40;12M"
Sleep 150ms
Escape
Type@1ms "[<64;40;12M"
Sleep 150ms
Escape
Type@1ms "[<64;40;12M"
Sleep 150ms
Sleep 200ms
Screenshot indicator.png
Sleep 1s
Hide
Ctrl+]
Type@5ms "q"
Enter
Show
Type "q"
Sleep 500ms
Hide
Ctrl+]
Type@5ms "tmux set -g @scroll_revamped_status_wheel on; scroll-revamped apply"
Enter
Show
Type "tmux set -g @scroll_revamped_status_wheel on; scroll-revamped apply"
Sleep 400ms
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1s
Hide
Ctrl+]
Type@5ms "Mouse wheel down over the status line"
Enter
Show
Escape
Type@1ms "[<65;20;1M"
Sleep 150ms
Sleep 1s
Screenshot status-wheel.png
Sleep 1500ms
Hide
Ctrl+]
Type@5ms "tmux set -g @scroll_revamped_smooth on; scroll-revamped apply"
Enter
Show
Type "tmux set -g @scroll_revamped_smooth on; scroll-revamped apply"
Sleep 400ms
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1s
Hide
Type "clear; seq -f 'note %g' 1 200"
Enter
Sleep 500ms
Show
Hide
Ctrl+]
Type@5ms "Mouse wheel up"
Enter
Show
Escape
Type@1ms "[<64;40;12M"
Sleep 150ms
Escape
Type@1ms "[<64;40;12M"
Sleep 150ms
Escape
Type@1ms "[<64;40;12M"
Sleep 150ms
Escape
Type@1ms "[<64;40;12M"
Sleep 150ms
Escape
Type@1ms "[<64;40;12M"
Sleep 150ms
Escape
Type@1ms "[<64;40;12M"
Sleep 150ms
Escape
Type@1ms "[<64;40;12M"
Sleep 150ms
Escape
Type@1ms "[<64;40;12M"
Sleep 150ms
Sleep 800ms
Screenshot smooth.png
Sleep 1s
Hide
Ctrl+]
Type@5ms "q"
Enter
Show
Type "q"
Sleep 500ms
Hide
Ctrl+]
Type@5ms "tmux set -g @scroll_revamped_click_copy on; scroll-revamped apply"
Enter
Show
Type "tmux set -g @scroll_revamped_click_copy on; scroll-revamped apply"
Sleep 400ms
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1s
Hide
Type "clear; echo deploy finished at noon"
Enter
Sleep 500ms
Show
Hide
Ctrl+]
Type@5ms "Double click"
Enter
Show
Sleep 500ms
Escape
Type@1ms "[<0;10;3M"
Sleep 60ms
Escape
Type@1ms "[<0;10;3m"
Sleep 60ms
Escape
Type@1ms "[<0;10;3M"
Sleep 60ms
Escape
Type@1ms "[<0;10;3m"
Sleep 60ms
Sleep 2s
Hide
Ctrl+]
Type@5ms "cat clipboard; echo"
Enter
Show
Type "cat clipboard; echo"
Sleep 400ms
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1s
Screenshot click-copy.png
Sleep 1500ms

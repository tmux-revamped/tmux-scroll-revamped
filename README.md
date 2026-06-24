<div align="center">

<h1>tmux-scroll-revamped</h1>

**Mouse wheel that does the right thing: scroll vim and less directly, copy-mode everywhere else.**

[![Tests](https://github.com/gufranco/tmux-scroll-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/gufranco/tmux-scroll-revamped/actions/workflows/tests.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

**native routing** · **no per-event fork** · **tmux 1.9 to 3.5** · **35** tests · **95%+** coverage

Makes the mouse wheel behave. When the foreground program scrolls itself, vim, less, man, htop, the wheel goes straight to it. Everywhere else, the wheel enters copy-mode and scrolls the scrollback. On tmux 3.1+ the decision is a **native regex match** over `#{pane_current_command}`, so unlike mighty-scroll there is no process-tree walk and no shell forked on every wheel tick.

Built from [tmux-plugin-template](https://github.com/gufranco/tmux-plugin-template).

<table>
<tr>
<td><strong>Native routing</strong><br>On tmux 3.1+ the wheel rule is a tmux format match, zero forks per scroll event.</td>
<td><strong>No process walk</strong><br>Reads <code>#{pane_current_command}</code> directly instead of crawling the process tree.</td>
</tr>
<tr>
<td><strong>Knows your apps</strong><br>A long default list of full-screen programs, fully configurable.</td>
<td><strong>Graceful fallback</strong><br>Older tmux without regex match uses a tiny check command instead.</td>
</tr>
</table>

## Usage

Install it and scroll. Over vim, less, htop, and friends the wheel scrolls the app. Over a shell prompt it scrolls the tmux history. Nothing to press.

## Install

With [TPM](https://github.com/tmux-plugins/tpm), add to `~/.tmux.conf`:

```tmux
set -g @plugin 'gufranco/tmux-scroll-revamped'
```

Press `prefix + I`. Mouse mode is enabled automatically unless you opt out.

## Configuration

| Option | Default | Meaning |
|--------|---------|---------|
| `@scroll_revamped_passthrough_apps` | a long default list (vim, nvim, less, man, htop, fzf, lazygit, ...) | programs that receive the wheel directly |
| `@scroll_revamped_mouse` | `on` | set to `off` to manage `mouse` yourself |
| `@scroll_revamped_speed` | unset | a positive integer caps copy-mode wheel scrolling to that many lines per tick, taming fast trackpad flicks; unset keeps tmux's default |

To add an app, set the full list including the defaults you want to keep:

```tmux
set -g @scroll_revamped_passthrough_apps 'vim nvim less man htop my-tui-app'
```

## Compatibility

Works on every tmux version TPM supports, 1.9 and up, on Linux (x86_64 and arm64) and macOS (Intel and Apple Silicon). tmux 3.1+ gets the fork-free native routing; older versions fall back to a per-event check command.

## Development

```bash
make test    # bats suite
make lint    # shellcheck
make coverage  # kcov line coverage on Linux
```

The match-pattern builder and membership check live in [`src/lib/scroll/scroll.sh`](src/lib/scroll/scroll.sh) as pure functions, fixture-tested, while the wheel bindings are wired in [`scroll-revamped.tmux`](scroll-revamped.tmux).

## License

[MIT](LICENSE), copyright Gustavo Franco.

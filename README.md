<div align="center">

<h1>tmux-scroll-revamped</h1>

**Mouse wheel that does the right thing: scroll the app directly, copy-mode everywhere else. No app names to configure.**

[![Tests](https://github.com/tmux-revamped/tmux-scroll-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-scroll-revamped/actions/workflows/tests.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) [![Version](https://img.shields.io/badge/version-2.1.0-blue.svg)](CHANGELOG.md)

</div>

**name-free routing** · **no per-event fork** · **tmux 1.9 to 3.5** · **87** tests · **95%+** coverage

Makes the mouse wheel behave, with nothing to configure. A full-screen app on the alternate screen, a TUI like Claude Code, vim, less, or htop, owns the wheel, and so does any app that has turned on mouse reporting. Everywhere else the wheel enters copy-mode and scrolls the scrollback. Detection reads two tmux formats, `#{alternate_on}` and `#{mouse_any_flag}`, so every app that can use the wheel gets it without ever being named. On tmux 3.1+ the decision is a **native format match**, so unlike mighty-scroll there is no process-tree walk and no shell forked on every wheel tick.

Built from [tmux-plugin-template](https://github.com/tmux-revamped/tmux-plugin-template).

<table>
<tr>
<td><strong>Native routing</strong><br>On tmux 3.1+ the wheel rule is a tmux format match, zero forks per scroll event.</td>
<td><strong>No process walk</strong><br>Reads tmux pane formats directly instead of crawling the process tree.</td>
</tr>
<tr>
<td><strong>No app list</strong><br>Detects apps by the alternate screen and by mouse reporting, so nothing needs to be named.</td>
<td><strong>Graceful fallback</strong><br>Older tmux without the format operators uses a tiny check command instead.</td>
</tr>
</table>

## Usage

Install it and scroll. Over vim, less, htop, a full-screen TUI, and friends the wheel scrolls the app. Over a shell prompt it scrolls the tmux history. Nothing to press.

## Install

With [TPM](https://github.com/tmux-plugins/tpm), add to `~/.tmux.conf`:

```tmux
set -g @plugin 'tmux-revamped/tmux-scroll-revamped'
```

Press `prefix + I`. Mouse mode is enabled automatically unless you opt out.

## Configuration

Detection works out of the box. The options below only exist to turn a heuristic off or to tune copy-mode.

| Option | Default | Meaning |
|--------|---------|---------|
| `@scroll_revamped_passthrough_alternate` | `on` | pass the wheel to any app on the alternate screen; set to `off` to route alternate-screen panes into copy-mode |
| `@scroll_revamped_passthrough_mouse` | `on` | pass the wheel to any app that has turned on mouse reporting; set to `off` to ignore the app's mouse mode |
| `@scroll_revamped_mouse` | `on` | set to `off` to manage `mouse` yourself |
| `@scroll_revamped_speed` | unset | a positive integer caps copy-mode wheel scrolling to that many lines per tick, taming fast trackpad flicks; unset keeps tmux's default |
| `@scroll_revamped_select_pane` | `off` | set to `on` to focus the pane under the wheel before scrolling |
| `@scroll_revamped_skip_empty` | `off` | set to `on` to keep the wheel out of copy-mode on a pane with no scrollback |
| `@scroll_revamped_alt_keys` | unset | `arrow` or `page` translates the wheel into arrow or page keys for an alternate-screen app with mouse reporting off (less, man, vi), so the wheel finally scrolls it; arrow mode uses `@scroll_revamped_speed` as the count |
| `@scroll_revamped_status_wheel` | `off` | set to `on` to switch windows when the wheel rolls over the status line |
| `@scroll_revamped_granularity` | `line` | how far one copy-mode wheel tick scrolls: `line`, `halfpage`, or `page` |
| `@scroll_revamped_auto_exit` | `off` | set to `on` to leave copy-mode when a downward tick is already at the bottom |
| `@scroll_revamped_indicator` | `off` | set to `on` to flash the copy-mode scroll position on each tick (tmux 2.9+) |
| `@scroll_revamped_drag_copy` | `off` | set to `on` to copy a mouse drag-selection to the system clipboard (pbcopy, wl-copy, xclip, or xsel) |

With both heuristics off the wheel only ever drives copy-mode, since nothing is left to detect a self-scrolling app by.

## Compatibility

Works on every tmux version TPM supports, 1.9 and up, on Linux (x86_64 and arm64) and macOS (Intel and Apple Silicon). tmux 3.1+ gets the fork-free native routing through the `#{||:}` format operator; older versions fall back to a per-event check command. `#{alternate_on}` and `#{mouse_any_flag}` exist on every supported version.

## Development

```bash
make test    # bats suite
make lint    # shellcheck
make coverage  # kcov line coverage on Linux
```

The passthrough predicates live in [`src/lib/scroll/scroll.sh`](src/lib/scroll/scroll.sh) as pure functions, fixture-tested. The wheel bindings are built in [`src/lib/scroll/routing.sh`](src/lib/scroll/routing.sh) behind a single applier seam, so every routing branch is asserted through a dry-run applier that never touches a live tmux; [`scroll-revamped.tmux`](scroll-revamped.tmux) is a thin entry point that applies them.

## License

[MIT](LICENSE), copyright Gustavo Franco.

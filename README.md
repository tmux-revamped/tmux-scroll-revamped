<div align="center">

# tmux-scroll-revamped

<strong>Send the mouse wheel to apps that scroll themselves and into tmux copy-mode everywhere else.</strong>

English | [日本語](README.ja.md) | [简体中文](README.zh-Hans.md) | [繁體中文（香港）](README.zh-HK.md)

[![Tests](https://github.com/tmux-revamped/tmux-scroll-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-scroll-revamped/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-3.0.0-blue.svg)](CHANGELOG.md)

<p align="center">
  <a href="#what-it-does">What it does</a> |
  <a href="#installation">Installation</a> |
  <a href="#usage">Usage</a> |
  <a href="#configuration">Configuration</a> |
  <a href="#key-bindings">Key bindings</a> |
  <a href="#how-it-works">How it works</a>
</p>

</div>

**0 processes forked per wheel tick on tmux 2.0 and later. 0 app names to configure. 13 options. Tested on macOS and Linux.**

---

## What it does

A full-screen app on the alternate screen, such as vim, less, htop or Claude Code, gets the wheel. So does any app that turned on mouse reporting. Over a shell prompt the wheel enters copy-mode and scrolls the tmux history. The decision reads two tmux formats, `#{alternate_on}` and `#{mouse_any_flag}`, so no app has to be named.

Optional settings tune copy-mode scrolling: lines per tick, half pages or pages, leaving copy-mode at the bottom, a scroll position flash, and copying a mouse selection to the system clipboard.

## Requirements

| Requirement | Version or note |
|:------------|:----------------|
| tmux | 3.2 or later. The bindings also build on tmux 1.9 to 3.1, with the fallbacks in [How it works](#how-it-works) |
| bash | 3.2 or later, so the stock macOS `/bin/bash` works |
| Operating system | macOS on Apple Silicon and Intel, Linux on x86_64 and arm64 |
| Core tools | BSD, GNU or uutils coreutils |
| Clipboard tool | Optional, for `@scroll_revamped_drag_copy`: `pbcopy` on macOS, `wl-copy`, `xclip` or `xsel` on Linux |

## Installation

With [TPM](https://github.com/tmux-plugins/tpm), add the plugin to `~/.tmux.conf`, turn the wheel routing on, and press `prefix + I`:

```tmux
set -g @plugin 'tmux-revamped/tmux-scroll-revamped'
set -g @scroll_revamped_wheel 'on'
```

Without TPM, clone the repository and run the entry point from `~/.tmux.conf`:

```sh
git clone https://github.com/tmux-revamped/tmux-scroll-revamped ~/.tmux/plugins/tmux-scroll-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-scroll-revamped/scroll-revamped.tmux
```

## Usage

With `@scroll_revamped_wheel` on, scroll. Over vim, less, htop or a full-screen TUI the wheel scrolls the app. Over a shell prompt it scrolls the tmux history. There is nothing to press.

The plugin also turns tmux's `mouse` option on when it loads. Set `@scroll_revamped_mouse` to `off` to manage that option yourself.

A setup that scrolls 3 lines per tick and leaves copy-mode at the bottom:

```tmux
set -g @scroll_revamped_wheel 'on'
set -g @scroll_revamped_speed '3'
set -g @scroll_revamped_auto_exit 'on'
```

## Configuration

Set any option in `~/.tmux.conf` before the plugin loads.

| Option | Default | Meaning |
|:-------|:--------|:--------|
| `@scroll_revamped_wheel` | `off` | `on` binds the root-table `WheelUpPane` and `WheelDownPane` that route the wheel. `off` leaves tmux's own wheel bindings in place |
| `@scroll_revamped_passthrough_alternate` | `on` | Pass the wheel to any app on the alternate screen. `off` sends those panes into copy-mode |
| `@scroll_revamped_passthrough_mouse` | `on` | Pass the wheel to any app that turned on mouse reporting. `off` ignores the app's mouse mode |
| `@scroll_revamped_skip_empty` | `off` | `on` keeps the wheel out of copy-mode on a pane with no scrollback |
| `@scroll_revamped_select_pane` | `off` | `on` focuses the pane under the pointer before scrolling |
| `@scroll_revamped_alt_keys` | unset | `arrow` or `page` turns the wheel into arrow or page keys for an alternate-screen app with mouse reporting off, such as less, man or vi. Arrow mode sends `@scroll_revamped_speed` keys per tick, 3 when unset, at most 20 |
| `@scroll_revamped_mouse` | `on` | `off` stops the plugin from setting tmux's `mouse` option |
| `@scroll_revamped_speed` | unset | A positive integer sets the lines one copy-mode wheel tick scrolls |
| `@scroll_revamped_granularity` | `line` | How far one copy-mode tick scrolls: `line`, `halfpage` or `page` |
| `@scroll_revamped_auto_exit` | `off` | `on` leaves copy-mode when a downward tick is already at the bottom |
| `@scroll_revamped_indicator` | `off` | `on` flashes the scroll position, such as `scroll 120/4000`, on each copy-mode tick |
| `@scroll_revamped_drag_copy` | `off` | `on` copies a mouse selection in copy-mode to the system clipboard |
| `@scroll_revamped_status_wheel` | `off` | `on` switches windows when the wheel rolls over the status line |

With both passthrough options off, the wheel always enters copy-mode.

### Internal state

The plugin manages these options itself. Do not set them.

| Option | Holds |
|:-------|:------|
| `@scroll_revamped_cache_key` | The pane, alternate-screen, mouse and scrollback state of the last decision made by the tmux 1.9 check command |
| `@scroll_revamped_cache_val` | That decision: `0` passes the wheel to the app, `1` enters copy-mode |

## Key bindings

The plugin binds no prefix key. Its bindings are mouse events, and each one waits for an option.

| Key | Table | Bound when |
|:----|:------|:-----------|
| `WheelUpPane`, `WheelDownPane` | root | `@scroll_revamped_wheel` is `on` |
| `WheelUpPane`, `WheelDownPane` | `copy-mode`, `copy-mode-vi` | `@scroll_revamped_speed` is set, `@scroll_revamped_granularity` is not `line`, or `@scroll_revamped_auto_exit` or `@scroll_revamped_indicator` is `on` |
| `MouseDragEnd1Pane` | `copy-mode`, `copy-mode-vi` | `@scroll_revamped_drag_copy` is `on` and a clipboard tool is found |
| `WheelUpStatus`, `WheelDownStatus` | root | `@scroll_revamped_status_wheel` is `on` |

The root table is opt-in across the tmux-revamped family, so from 3.0.0 the wheel bindings wait for `@scroll_revamped_wheel`. The copy-mode bindings work whether or not the wheel routing is on.

## How it works

**Routing.** `WheelUpPane` checks one condition: the pane is on the alternate screen, or its app turned on mouse reporting, or the pane is already in a mode. When true, the wheel event goes to the pane with `send-keys -M`. When false, tmux enters copy-mode with `copy-mode -e`, which leaves again when you scroll back to the bottom. `WheelDownPane` always forwards the event, so it scrolls the app or the open copy-mode.

**No fork per tick.** The condition is a tmux format inside `if-shell -F`, evaluated by tmux itself.

| tmux | Routing |
|:-----|:--------|
| 3.1 and later | `#{\|\|:}` and `#{&&:}` format operators |
| 2.0 to 3.0 | The same condition built from nested `#{?}` |
| 1.9 | [`src/scroll.sh`](src/scroll.sh) `check` runs on each tick, and its answer is cached per pane state |

**Copy-mode tuning.** Speed, granularity, auto-exit and the indicator rebind the wheel in the `copy-mode` and `copy-mode-vi` tables, on tmux 2.4 and later. The indicator needs tmux 3.2, the first release whose `display-message` accepts `-d`. The status-line wheel needs tmux 2.1.

## Development

| Command | What it does |
|:--------|:-------------|
| `make test` | Runs the bats suite |
| `make lint` | Runs shellcheck on every shell file |
| `make coverage` | Measures line coverage with kcov and fails below 95 percent, on Linux |

The bindings are built in [`src/lib/scroll/routing.sh`](src/lib/scroll/routing.sh) through one function that issues every tmux command, so the tests check each binding without a live tmux server.

## License

[MIT](LICENSE)

<!-- family:begin -->

## The tmux-revamped family

This plugin is one member of the tmux-revamped family. Every member carries the
same contract in [`FAMILY.md`](FAMILY.md), the same tooling under `family/`, and
the same shared library, all held byte-identical by a checksum manifest. They are
built to be installed together: no member claims a key or a tmux option that
another member claims.

A defect found in one member is hunted across all of them before the fix is
called done. That obligation is written into the contract rather than left to
memory, and `family/bin/sweep` is how it is discharged.

| Member | What it does |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | Edit your tmux config, save, and watch it reload itself, no key, no command |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | Battery status for your tmux status bar, without ever blocking the status render |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | Every connected Bluetooth device and its battery in your tmux status bar, without blocking the render |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | CPU load, temperature, and frequency in your tmux status bar, without ever blocking the render |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | Disk usage for your tmux status bar, without ever blocking the status render |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | Pick a URL, path, hash or any other token off the screen with fzf and type it at the cursor, in pure shell |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | Switch to, kill, rename or create tmux sessions, windows and panes from fzf pickers in a popup |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | Show the active pane's git branch, changes and provider counts in the tmux status bar without blocking it |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | GPU load, temperature, clock, power and memory in the tmux status bar, from NVIDIA, AMD, Intel and Apple GPUs |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | Current Kubernetes context and namespace in the tmux status bar, parsed from kubeconfig without kubectl |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | Launch any TUI app in a popup or a window, scoped to the current pane's directory, with one configurable bindi |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | Capture any pane to a file: live logging, full scrollback, or a one-shot screenshot |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | Now playing in your tmux status bar, without ever blocking the status render |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | Network throughput in your tmux status bar, without ever blocking the render |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | Pane and window management bindings for tmux, version aware, vim friendly, every prefix key can be disabled |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | Save every tmux session, window and pane, auto-save on a timer, and restore it all after a reboot |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | The starting point for a tmux-revamped plugin: shared library, bats harness, CI and family tooling |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | A Pomodoro timer in the tmux status bar that keeps all of its state in tmux options, with no temp files |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM, swap and memory pressure in the tmux status bar, sampled in the background so the render never waits |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | Drag a window tab along the tmux status bar with the mouse to move that window |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | **this plugin**, Send the mouse wheel to apps that scroll themselves and into tmux copy-mode everywhere else |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | Sensible tmux defaults, gated by tmux version and terminal, that leave the options you set alone |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | Tiling window management for tmux: eight layouts including BSP dwindle and spiral, with layout undo |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | Local and world clocks for the tmux status bar, colored by time of day, with countdowns and a DST warning |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | Weather for the tmux status bar from wttr.in, fetched in the background so the status line never waits |

### Checking an installation

With every member on disk, one command reports any conflict between them:

```sh
family/bin/doctor --live
```

It reads each member and the running tmux server, and reports duplicate keys,
duplicate status placeholders, options outside the naming grammar, and any
member whose contract version has fallen behind.

<!-- family:end -->

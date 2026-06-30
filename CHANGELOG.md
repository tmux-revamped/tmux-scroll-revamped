# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2026-06-30

### Added

- `@scroll_revamped_select_pane` (default `off`) focuses the pane under the wheel
  before scrolling, so a tick on an inactive pane selects it first.
- `@scroll_revamped_skip_empty` (default `off`) keeps the wheel out of copy-mode on
  a pane with no scrollback by folding `#{history_size}` into the passthrough match.
- `@scroll_revamped_alt_keys` (`arrow` or `page`, default unset) translates the
  wheel into arrow or page keys for an alternate-screen app that has not turned on
  mouse reporting, so less, man, and vi with the mouse off finally scroll. Arrow
  mode honors `@scroll_revamped_speed` as the lines-per-tick count.
- `@scroll_revamped_status_wheel` (default `off`) switches windows when the wheel
  rolls over the status line.
- `@scroll_revamped_granularity` (`line`, `halfpage`, or `page`, default `line`)
  sets how far one wheel tick scrolls in copy-mode.
- `@scroll_revamped_auto_exit` (default `off`) leaves copy-mode automatically when a
  downward tick is already at the bottom of the scrollback.
- `@scroll_revamped_indicator` (default `off`, tmux 2.9+) flashes the copy-mode
  scroll position as `#{scroll_position}/#{history_size}` on each tick.
- `@scroll_revamped_drag_copy` (default `off`) copies a mouse drag-selection to the
  system clipboard via `pbcopy`, `wl-copy`, `xclip`, or `xsel`, restoring the
  selection that enabling `mouse` otherwise takes over.

### Changed

- tmux 2.0 through 3.0 now route the wheel with a fork-free `if-shell -F` over a
  nested `#{?}` condition instead of forking a check command on every event. tmux
  3.1+ keeps the native `#{||:}` match. Only tmux 1.9 still forks, and that decision
  is now cached per pane so an unchanged pane skips recomputation.
- Routing logic moved into `src/lib/scroll/routing.sh` behind a single applier seam,
  so the full binding set is unit tested through a dry-run applier that never touches
  a live tmux.

## [2.0.0] - 2026-06-29

### Added

- `@scroll_revamped_passthrough_mouse` (default `on`) passes the wheel to any pane
  whose foreground app has turned on mouse reporting, so a TUI that requests the
  mouse scrolls itself without being named. The routing keys on `#{mouse_any_flag}`,
  which exists on every tmux TPM supports. Set it `off` to ignore the app's mouse
  mode.

### Removed

- **Breaking:** `@scroll_revamped_passthrough_apps` and the app-name list it fed.
  `send-keys -M` only reaches an app that has turned on mouse reporting, and that
  app is already detected by `#{mouse_any_flag}`; a full-screen app is detected by
  `#{alternate_on}`. The name list therefore added no behavior the two formats did
  not already cover, while forcing passthrough to a named app even when it had mouse
  mode off. Detection is now purely name-free. Anyone who set the option should
  remove it; the apps it listed are detected automatically.

### Changed

- The fast tmux 3.1+ binding no longer builds or matches a regex over
  `#{pane_current_command}`. It is a plain `#{||:}` of `#{alternate_on}` and
  `#{mouse_any_flag}`, so there is one fewer subshell at plugin load and a smaller
  binding.

## [1.2.0] - 2026-06-29

### Added

- `@scroll_revamped_passthrough_alternate` (default `on`) passes the wheel to any
  app on the alternate screen, so full-screen TUIs that are not on the app list,
  such as Claude Code, scroll themselves instead of dropping into copy-mode over
  the primary-screen scrollback behind them. Set it `off` to route purely by the
  app list.

### Fixed

- A full-screen app not on the passthrough list received copy-mode scrolling of
  the scrollback behind it instead of the wheel. The routing now also keys on
  `#{alternate_on}`.

## [1.1.0] - 2026-06-23

### Added

- `@scroll_revamped_speed` throttles copy-mode wheel scrolling to a fixed number
  of lines per tick, so a fast trackpad flick no longer jumps whole pages
  (upstream tmux-mighty-scroll #7).

## [1.0.0] - 2026-06-22

### Added

- Smart mouse wheel: full-screen apps (vim, less, htop) receive the wheel
  directly, everything else enters copy-mode.
- On tmux 3.1+ the routing is a native regex match over the pane's foreground
  command, with no process-tree walk and no fork per wheel event.
- A graceful per-event check fallback for older tmux.
- Configurable passthrough app list and an opt-out for mouse management.

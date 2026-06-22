# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-06-22

### Added

- Smart mouse wheel: full-screen apps (vim, less, htop) receive the wheel
  directly, everything else enters copy-mode.
- On tmux 3.1+ the routing is a native regex match over the pane's foreground
  command, with no process-tree walk and no fork per wheel event.
- A graceful per-event check fallback for older tmux.
- Configurable passthrough app list and an opt-out for mouse management.

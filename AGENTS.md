# tmux-scroll-revamped

Guidance for anyone, human or agent, changing tmux-scroll-revamped. What it is and how to use it lives in [README.md](README.md).

[FAMILY.md](FAMILY.md) holds everything this plugin shares with the rest of the tmux-revamped family, and it is the same in every member. This file holds only what is exclusive to tmux-scroll-revamped, under the same headings as the agent guide of every member. Read both before changing anything; a rule that would serve the other members goes into [`FAMILY.md`](FAMILY.md) instead of here.

## Layout

| Path | Holds |
|:-----|:------|
| [`scroll-revamped.tmux`](scroll-revamped.tmux) | The entry point TPM runs |
| [`src/scroll.sh`](src/scroll.sh) | The script the entry point and the keys call |
| [`src/lib/scroll/`](src/lib/scroll) | This member's modules |
| [`src/lib/utils/constants.sh`](src/lib/utils/constants.sh) | This member's constants, including its version |
| [`src/lib/utils/`](src/lib/utils), [`src/lib/tmux/`](src/lib/tmux) | The shared library. Every file there except `constants.sh` is owned by the family |
| [`test/`](test) | The bats suite. `helpers.bash` and `tmux_helpers.bash` are owned; this member's own mocks go in the `_local` files |
| [`family/`](family) | The family tooling, owned |

## Names

- Settings are tmux options named `@scroll_revamped_<setting>`.
- It has no status placeholders.
- Public functions carry `scroll_`; private ones start with `_`.
- The version constant is `SCROLL_REVAMPED_VERSION`.
- Its command-line tool, once it exists, is `scroll-revamped`.

## Behaviour

- Sends the mouse wheel to apps that scroll themselves and into copy-mode everywhere else.
- It binds the mouse wheel in the root, `copy-mode` and `copy-mode-vi` tables.
- `WheelUpPane` sends the event to the pane with `send-keys -M` when the pane is on the alternate screen, its app turned on mouse reporting, or it is already in a mode, and enters copy-mode with `copy-mode -e` otherwise.

## Domain rules

- The condition is a tmux format inside `if-shell -F`, evaluated by tmux, so no process starts per wheel tick: `#{||:}` and `#{&&:}` on tmux 3.1 and later, nested `#{?}` on 2.0 to 3.0.
- On tmux 1.9 `src/scroll.sh check` runs on each tick and caches its answer per pane state.
- The copy-mode indicator needs tmux 3.2, the first release whose `display-message` accepts `-d`.

## Release

- `SCROLL_REVAMPED_VERSION` in [`src/lib/utils/constants.sh`](src/lib/utils/constants.sh) holds the version. It must equal the newest versioned heading in [`CHANGELOG.md`](CHANGELOG.md) and the README's version badge, which the `version` job in `tests.yml` checks.
- A push to `main` whose version has no tag yet makes the `release` job in `tests.yml` tag `vX.Y.Z` and publish a GitHub release with that changelog section.
- Unreleased changes sit under `## [Unreleased]` in [`CHANGELOG.md`](CHANGELOG.md) until a release is cut.

## Gaps against FAMILY.md

As of 2026-11-15:

- Every script is bash, under `#!/usr/bin/env bash`, not POSIX `sh`, so it is untested under `dash`, `zsh` and BusyBox `sh`.
- The code lives in [`src/`](src) and [`src/lib/`](src/lib); there is no `bin/scroll-revamped`, `lib/state.sh` or `lib/core.sh`.
- No `scroll-revamped` command with `help`, `version` and `doctor` in the family's form, no man page, no completions and no `manifest.json`.
- No gum interface: no `lib/ui.sh`, `lib/table.awk`, themes or `test/bin/gum`.
- No `screens/` and no recordings in the README.
- The README sections are not the family's order of Quick start, Usage, topic sections, Portability, Development and License.
- Coverage is kcov with a 95 percent floor on Linux, not bashcov at 100 percent merged from macOS and Linux.
- CI tests GNU, BSD and uutils tools in `tests.yml`, but not the six toolsets through `.github/scripts/toolset.sh`, and no shell matrix under `sh`, `dash`, `bash` and `zsh`.
- No golden transcripts, `call.sh`, `run-matrix.sh` or `linux-container.sh`.
- The version is written by hand and released by `tests.yml`; there is no semantic-release, `package.json`, `release.yml` with `recover`, `bot-merge.yml` or Renovate.
- CI is `tests.yml`, `family.yml` and `security.yml`, not `ci.yml`, and no job starts with `step-security/harden-runner`.
- No `.editorconfig`, `.yamllint.yml`, `scripts/check-names.sh` or shfmt; the Makefile has `help`, `test`, `test-unit`, `coverage`, `lint` and `clean`, not the family's targets.

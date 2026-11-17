# tmux-scroll-revamped

Guidance for anyone, human or agent, changing tmux-scroll-revamped. What it is and how to use it lives in [README.md](README.md).

[FAMILY.md](FAMILY.md) holds everything this plugin shares with the rest of the tmux-revamped family, and it is the same in every member. This file holds only what is exclusive to tmux-scroll-revamped, under the same headings as the agent guide of every member. Read both before changing anything; a rule that would serve the other members goes into [`FAMILY.md`](FAMILY.md) instead of here.

## Layout

| Path | Holds |
|:-----|:------|
| [`scroll-revamped.tmux`](scroll-revamped.tmux) | The entry point TPM runs: it runs `bin/scroll-revamped apply` |
| [`bin/scroll-revamped`](bin/scroll-revamped) | The command: `apply`, `list`, `check`, `doctor`, `version`, `help` and the menu. `apply` and `check` run without loading the interface modules |
| [`lib/scroll.sh`](lib/scroll.sh) | Reading the settings, the version checks, the binding plan and the `check` decision with its cache |
| [`lib/state.sh`](lib/state.sh) | Every global, including `SCROLL_REVAMPED_SETTINGS`, the table of setting names and defaults the rest reads |
| [`lib/core.sh`](lib/core.sh) | The version |
| [`lib/`](lib) | Every other file is the shared library, identical in every member |
| [`test/scroll.bats`](test/scroll.bats), [`test/scroll-tuning.bats`](test/scroll-tuning.bats), [`test/commands.bats`](test/commands.bats), [`test/entrypoint.bats`](test/entrypoint.bats), [`test/scroll-smooth.bats`](test/scroll-smooth.bats), [`test/wheel.bats`](test/wheel.bats), [`test/clicks.bats`](test/clicks.bats), [`test/smooth.bats`](test/smooth.bats) | This member's suites: the library, the commands, the entry point and `check` on a private tmux server, and real wheel and drag events sent through a second tmux attached to it |
| [`screens/`](screens) | The tapes and the recording's tmux config, which turns the wheel routing on and puts the status line on top; the hero tape sends real wheel events as typed SGR mouse sequences |

## Names

- Settings are the tmux options `@scroll_revamped_<setting>` listed in `SCROLL_REVAMPED_SETTINGS`, the long options with dashes, such as `--skip-empty`, and the environment variables `SCROLL_REVAMPED_<SETTING>`.
- `@scroll_revamped_cache_key` and `@scroll_revamped_cache_val` hold the last `check` decision; they are state, never settings.
- It has no status placeholders.
- The version constant is `SCROLL_REVAMPED_VERSION`.

## Behaviour

- `apply` reads every setting with one `tmux display-message` call and one `env` read, builds the plan, and sends every command to tmux in one call separated by `;`. Nothing runs in the background afterwards.
- An empty tmux option means its default.
- The entry point clears every inherited `REVAMPED_` variable except the test switches, and every `SCROLL_REVAMPED_*_LOADED` guard; every other global is assigned outright in the state module.
- It binds no prefix key; it owns the root-table wheel keys, declared in the family key allocation, and only when `@scroll_revamped_wheel` is on.

## Domain rules

- On tmux 2.0 and later the wheel is decided by a format inside `if-shell -F`, so no process starts per tick: native `#{||:}` and `#{&&:}` on 3.1 and later, nested `#{?}` below.
- On tmux 1.9 each tick runs `check` with the pane's alternate, mouse and history flags; a flag an option turns off is passed as a constant, and the decision is cached per pane state in one `display-message` read and one `set-option` write.
- The tool path in the 1.9 binding is quoted for `sh`, then escaped for a tmux double-quoted string, with `#` doubled, so a checkout path with a space, a quote or a hash survives.
- Arrow alt keys repeat the key `@scroll_revamped_speed` times, 3 when unset, capped at 20 by length before the value is compared, so a huge number never overflows the shell. Alt keys need tmux 2.0.
- The tick that takes a pane into copy-mode also scrolls it: on tmux 2.4 and later it runs the tuned copy-mode tick, or tmux's own five lines when nothing tunes it, because a pane in copy-mode ignores a forwarded mouse event; before 2.4 it forwards the event.
- Copy-mode tuning binds both copy-mode tables on tmux 2.4 and later; the indicator needs 3.2 and the status-line wheel 2.1.
- Drag copy and click copy use `pbcopy` on macOS, then `wl-copy`, `xclip` and `xsel`, and bind nothing when none exists; `doctor` names the one they would use.
- Click copy binds `DoubleClick1Pane` and `TripleClick1Pane` in the root table and both copy-mode tables on tmux 3.2 and later: it selects the word or the line, waits 0.3 seconds so the selection shows, as tmux's own binding does, pipes it to the clipboard tool and leaves copy-mode. A pane whose app asked for the mouse gets the click.
- Smooth scroll splits a line-granularity tick into steps joined by `run-shell -d 0.005`, on tmux 3.2 and later: one line per step up to 20 steps, the first step carrying the remainder above that, and one plain step for a speed of 1000 or more. Each step down after the first runs inside `if-shell -F "#{pane_in_mode}"`, because a pane entered with `copy-mode -e` leaves the mode at the bottom and a later step would print `Not in a mode`.

## Release

- `SCROLL_REVAMPED_VERSION` in [`lib/core.sh`](lib/core.sh) holds the version. Nobody edits it by hand.
- After a green `ci` run on `main`, [`release.yml`](.github/workflows/release.yml) runs semantic-release: a `feat` or `fix` since the last tag publishes a release, [`set-version.sh`](.github/scripts/set-version.sh) stamps the constant, and the notes go into [`CHANGELOG.md`](CHANGELOG.md).

## Gaps against FAMILY.md

As of 2026-11-17, none.

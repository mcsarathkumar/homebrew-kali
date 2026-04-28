# Contributing to homebrew-kali

This tap follows the same conventions as `homebrew-core`. Every formula must pass
`brew audit --strict --new`, `brew install --build-from-source`, and `brew test`
before being merged.

## Local dev loop

```bash
# 1. Clone and link the working tree as a local tap (one-time)
git clone https://github.com/mcsarathkumar/homebrew-kali.git
cd homebrew-kali
./scripts/dev-setup.sh
```

After `dev-setup.sh`, your `~/Workspace/homebrew-kali` checkout *is* the
`mcsarathkumar/kali` tap on your machine. Edits to `Formula/*.rb` are picked up
by `brew` immediately — no commit required.

```bash
# 2. Work on a feature branch
git checkout -b <formula>-<version>

# 3. Edit the formula, then run the same checks CI runs
brew audit --strict --new      mcsarathkumar/kali/<formula>
brew style --fix               mcsarathkumar/kali/<formula>
brew install --build-from-source --verbose mcsarathkumar/kali/<formula>
brew test                      mcsarathkumar/kali/<formula>

# 4. Push the branch and open a PR
git push origin <formula>-<version>
```

## CI

`.github/workflows/tests.yml` runs `brew test-bot` on every PR:

| Job | Runner | What it does |
|---|---|---|
| `tap-syntax` | `ubuntu-22.04` | `brew test-bot --only-tap-syntax` (lint + audit, no installs) |
| `test-bot` | `macos-14`, `macos-13`, `ubuntu-22.04` | `brew test-bot --only-formulae` — full install + test on each OS |

The `tap-syntax` job is the fan-in gate: if it fails, the macOS jobs are skipped.
PRs only pass when all three OS jobs are green.

If you need to skip CI for a docs-only change, prefix the commit subject with
`[skip ci]`.

## Conventions

- **Filename → class name:** strict CamelCase, hyphens stripped.
  `evil-winrm.rb` → `class EvilWinrm < Formula`.
- **License:** must be a valid SPDX identifier (`MIT`, `Apache-2.0`, etc.).
- **No `optional`/`recommended` deps** — those have been removed from modern
  Homebrew. All dependencies are required.
- **Tests must do something.** `assert_match` against real output is preferred
  over a bare `system bin/"foo", "--version"`.
- **Use `livecheck`** unless the URL pattern is auto-detected (GitHub releases,
  PyPI, CPAN, crates.io).
- **Commit messages** mirror homebrew-core:
  - new formula: `<name> <version> (new formula)`
  - version bump: `<name> <version>`
  - other: `<name>: <short description>`

## Reporting issues

Open an issue at <https://github.com/mcsarathkumar/homebrew-kali/issues> with:
- macOS version + chip (`sw_vers`, `uname -m`)
- Output of `brew config` and `brew doctor`
- The full failing `brew install -v` log

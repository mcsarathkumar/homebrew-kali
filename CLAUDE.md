# CLAUDE.md

Project guide for Claude Code working inside the **`mcsarathkumar/homebrew-kali`** Homebrew tap.

This file is auto-loaded by Claude Code on every session in this repo. Read it first before making changes.

## What this repo is

A Homebrew tap that brings **Kali Linux security tools** — and other Linux-only Debian/RPM-only packages — to macOS via:

```bash
brew tap mcsarathkumar/kali https://github.com/mcsarathkumar/homebrew-kali
brew install mcsarathkumar/kali/<formula>
```

The tap stores only `.rb` formula definitions. Upstream sources are fetched on demand at `brew install` time, so the repo stays small.

## Hard rule for code changes

> **Any code change in this project must be done via the `homebrew-kali-packager` agent.**

The agent definition is at `.claude/agents/homebrew-kali-packager.md`. The skill that backs it (workflows, references, lookup tables) lives at `.claude/skills/homebrew-kali-packager/`.

When the user asks to:

- create or modify a formula,
- bump a formula version,
- port a Kali/Linux-only tool to macOS,
- fix a `brew audit` / `brew style` error,

…delegate to the `homebrew-kali-packager` agent. Do not write Ruby formulae from your generic prior — always go through the skill so conventions and audit rules are honored.

## Repository layout

```
homebrew-kali/
├── CLAUDE.md                      ← you are here
├── README.md                      ← user-facing docs (install + usage)
├── CONTRIBUTING.md                ← contributor dev loop + conventions
├── LICENSE                        ← MIT (tap files only; upstream tools keep their own)
├── .gitignore
├── Formula/
│   └── seclists.rb                ← formulae go here, one per file
├── scripts/
│   └── dev-setup.sh               ← symlinks this clone as the local brew tap
├── .github/
│   ├── workflows/tests.yml        ← brew test-bot CI on PR + push
│   └── dependabot.yml             ← weekly action-version bumps
└── .claude/
    ├── agents/
    │   └── homebrew-kali-packager.md   ← the project agent
    └── skills/
        └── homebrew-kali-packager/
            ├── SKILL.md
            ├── references/        ← per-build-system + audit + livecheck guides
            └── workflows/         ← new-formula, version-bump, linux-port
```

## Existing formulae

| Formula | Description | Source pin |
|---|---|---|
| `seclists` | Wordlists for security testing (data-only) | `tag: 2026.1`, `revision: 190c6f7b…` |

To add a new one, run the `homebrew-kali-packager` agent with the upstream URL or tool name.

## Dev loop

Local iteration is one command:

```bash
./scripts/dev-setup.sh
# Symlinks ~/Workspace/homebrew-kali → $(brew --repository)/Library/Taps/mcsarathkumar/homebrew-kali
# After this, edits to Formula/*.rb are picked up by `brew` immediately.
```

Then for any formula `<name>`:

```bash
brew install --build-from-source --verbose mcsarathkumar/kali/<name>
brew test                                  mcsarathkumar/kali/<name>
brew audit --strict --new                  mcsarathkumar/kali/<name>
brew style --fix                           mcsarathkumar/kali/<name>
```

All four must succeed before opening a PR. CI runs the same checks on `macos-14`, `macos-13`, and `ubuntu-22.04`.

## Branch and commit conventions

- **Always work on a feature branch**, never directly on `main`.
- Branch name: `<formula>-<version>` (e.g. `gobuster-3.7.0`).
- Commit subjects mirror homebrew-core:
  - new formula → `<name> <version> (new formula)`
  - version bump → `<name> <new-version>`
  - other → `<name>: <short description>`
- Never `git push` without explicit user confirmation.

## CI overview

`.github/workflows/tests.yml` runs `brew test-bot`:

| Job | Runner | Purpose |
|---|---|---|
| `tap-syntax` | `ubuntu-22.04` | Audit + style only — fast fan-in gate |
| `test-bot` (PR only) | `macos-14`, `macos-13`, `ubuntu-22.04` | Full install + test + audit per OS |

If `tap-syntax` fails, the macOS jobs are skipped to save runner time. Bottle artifacts upload from each OS for the maintainer to inspect.

## Non-negotiable Homebrew conventions (summary)

The full list lives in the skill at `.claude/skills/homebrew-kali-packager/SKILL.md`. The headlines:

- **Class name** is the strict CamelCase of the filename (`feroxbuster.rb` → `class Feroxbuster < Formula`; `evil-winrm.rb` → `class EvilWinrm`).
- **License** must be a valid SPDX identifier.
- **No `optional` / `recommended` deps** — modern Homebrew rejects them.
- **`depends_on` order** is alphabetical; `=> :build` deps first.
- **Tests must be meaningful** — prefer `assert_match version.to_s, shell_output(...)` over a bare `system`.
- **Use `on_macos` / `on_linux` / `on_arm` / `on_intel`** for platform-conditional logic, not raw `OS.mac?` checks.
- **HTTPS** for `homepage` and `url`.
- **No `sudo`, `curl | sh` installers, hardcoded `/usr/local`, vendored random binaries.**

## When to ask the user

The packager agent should pause and ask when:

- Upstream has no releases, no tags, and a stale default branch (project may be abandoned).
- The tool requires Linux-only features (raw netlink sockets, `/proc`, BPF, kernel modules).
- The license is missing or unclear.
- A formula by the same name already exists in homebrew-core at the same version.

## References inside this repo

- `README.md` — user-facing install + examples.
- `CONTRIBUTING.md` — full contributor workflow.
- `.claude/skills/homebrew-kali-packager/SKILL.md` — the skill, with all references and workflows linked.
- `.claude/agents/homebrew-kali-packager.md` — the agent that wraps the skill.

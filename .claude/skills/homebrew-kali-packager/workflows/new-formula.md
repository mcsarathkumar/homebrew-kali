# Workflow: Create a new formula from a repo URL

When the user gives you a tool name or repo URL and wants a formula.

## Stage 0 — Pre-flight checks

Before writing anything, answer these questions out loud (briefly to the user):

1. **Is the tool already in homebrew-core?** Search `https://formulae.brew.sh/formula/<name>` or `brew search <name>`. If yes — stop and ask whether they want our tap version or core's.
2. **Is there a stable release?** Check Releases / Tags. If neither, switch to "pragmatic mode" — pin to a commit SHA.
3. **What's the build system?** `go.mod`, `Cargo.toml`, `setup.py`/`pyproject.toml`, `Gemfile`/`*.gemspec`, `Makefile.PL`, `configure.ac`/`configure`, `CMakeLists.txt`, `meson.build`?
4. **Is it Linux-only?** Look for raw Linux APIs in the source. If yes, see `references/linux-only-tools.md`.
5. **What's the license?** Look for `LICENSE`. Map to SPDX.

## Stage 1 — Read the matching language reference

Once you know the build system, read the matching file. Don't guess, don't write from memory:

- Go → read `references/go.md`
- Rust → read `references/rust.md`
- Python → read `references/python.md`
- Ruby gem → read `references/ruby.md`
- Perl → read `references/perl.md`
- C/C++ → read `references/c-make.md`
- Prebuilt binary → read `references/prebuilt.md`
- GUI app → read `references/cask.md`

## Stage 2 — Set up the tap working directory

```bash
# If the tap isn't cloned yet:
test -d ~/homebrew-kali || git clone https://github.com/mcsarathkumar/homebrew-kali.git ~/homebrew-kali
cd ~/homebrew-kali
git checkout main
git pull
git checkout -b <name>-<version>
```

## Stage 3 — Write the formula

Create `Formula/<name>.rb` based on the template in the language reference. Show the formula to the user before computing sha256.

## Stage 4 — Compute checksums

```bash
# For tarballs:
curl -sL "<url>" -o /tmp/src.tar.gz
shasum -a 256 /tmp/src.tar.gz

# For Python tarballs from PyPI:
pip download <package>==<version> --no-deps --no-binary :all: -d /tmp/pip-dl
shasum -a 256 /tmp/pip-dl/<package>-<version>.tar.gz
```

Plug the sha256 into the formula.

## Stage 5 — Generate auxiliary content

For Python: `brew update-python-resources <name>` (after the formula is saved).

For Go/Rust: usually nothing more needed.

For Ruby with bundler: may need `--standalone` bundler config — see `references/ruby.md`.

## Stage 6 — Local install + test

```bash
brew uninstall <name> 2>/dev/null
brew install --build-from-source --verbose --debug ./Formula/<name>.rb
```

If install fails, debug — never commit a formula that doesn't install.

```bash
brew test <name>
```

If test fails, fix the test or fix the install (don't ignore failed tests).

```bash
brew audit --strict --new --formula ./Formula/<name>.rb
brew style --fix ./Formula/<name>.rb
```

If audit produces warnings, see `references/audit-fixes.md`.

## Stage 7 — Show the user the final formula

Before committing, paste the final formula content for the user to approve.

## Stage 8 — Commit and push (with explicit user OK)

```bash
git add Formula/<name>.rb
git commit -m "<name> <version> (new formula)"
# Wait for user confirmation before pushing
git push origin <name>-<version>
```

If the user has GitHub Actions on the tap, mention they should check the CI run.

## Stage 9 — Confirm install path

Tell the user the exact command:
```bash
brew tap mcsarathkumar/kali  # only first time
brew install mcsarathkumar/kali/<name>
```

Or, since the formula is in their tap already and possibly merged to main:
```bash
brew update
brew install mcsarathkumar/kali/<name>
```

## What to ask the user before starting

If the user gave you only a tool name (no URL), ask:
- "I found `<name>` at `<upstream-url>` — is that the right project?"

If the build system is unclear:
- "This project has both a `Makefile` and a `Cargo.toml`. Which is the canonical build path?"

If you suspect Linux-only features:
- "This tool uses `<linux-feature>`. On macOS we'd need to either disable that feature or skip the formula. Which do you prefer?"

Otherwise, just go.

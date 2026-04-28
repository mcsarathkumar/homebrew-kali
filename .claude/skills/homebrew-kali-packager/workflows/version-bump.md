# Version bump workflow

When the user wants to update an existing formula in the tap to a newer upstream version.

## Trigger phrases

- "Bump nuclei to v3.4.0"
- "Update the gobuster formula"
- "There's a new feroxbuster release, update my tap"

## Steps

### 1. Locate the formula

```bash
cd ~/homebrew-kali  # or wherever the tap is cloned
ls Formula/<name>.rb
```

If it doesn't exist, this isn't a bump — switch to the new-formula workflow.

### 2. Verify the new version

```bash
# What does the formula currently say?
grep -E "url|sha256|version" Formula/<name>.rb

# What's the latest upstream?
brew livecheck --formula ./Formula/<name>.rb
```

If livecheck reports the same version, there's no bump needed — confirm with the user.

### 3. Try `brew bump-formula-pr` (the easy path)

For most formulae, this one command does everything:

```bash
brew bump-formula-pr --no-fork --no-browse \
  --version=<new-version> \
  ./Formula/<name>.rb
```

This:
- Computes the new sha256
- Updates `url` and `sha256` (and `version` if needed)
- Commits the change with a standard message
- Optionally pushes a PR (skip with `--no-fork`)

If it works, jump to step 6.

### 4. Manual bump (when `bump-formula-pr` can't help)

For Python formulae (resources need updating), git-pinned formulae, or anything `bump-formula-pr` refuses:

```rbex
# In the formula, update:
url "https://github.com/.../archive/refs/tags/v<NEW_VERSION>.tar.gz"
sha256 "<new sha>"
# revision  -> reset to 0 or remove if formula had patches
```

Compute the sha:
```bash
curl -sL "https://github.com/.../archive/refs/tags/v<NEW>.tar.gz" | shasum -a 256
```

For Python formulae with a new version, also re-run:
```bash
brew update-python-resources <name>
```
This re-resolves all the `resource` blocks.

For Rust formulae, regenerate the lockfile reference if upstream changed `Cargo.lock`:
```bash
# Usually nothing to do — just the version + sha bump
```

For Go formulae, check whether upstream changed `go.mod` requirements:
```bash
# Usually nothing to do — just the version + sha bump
```

### 5. Test the bumped formula

```bash
brew uninstall <name> 2>/dev/null
brew install --build-from-source --verbose ./Formula/<name>.rb
brew test <name>
brew audit --strict ./Formula/<name>.rb
```

All three must pass.

### 6. Commit + push

```bash
git checkout -b <name>-<new-version>
git add Formula/<name>.rb
git commit -m "<name> <new-version>"
git push origin <name>-<new-version>
```

If the user has CI on the tap (GitHub Actions running `brew test-bot`), wait for it to go green before merging.

### 7. Confirm with user

Tell the user exactly what to run:
```bash
brew update
brew upgrade mcsarathkumar/kali/<name>
```

## When a bump is more than a version+sha

These cases need the full new-formula workflow even though it looks like a bump:

- **Major version with breaking deps**: e.g. tool moved from Python 3.9 to 3.12, or from openssl@1.1 to openssl@3.
- **Build system change**: e.g. moved from Make to CMake, or autotools to Meson.
- **License change**: rare but happens. Update `license`.
- **New optional features**: if upstream now requires a new dep (e.g. now needs `pcre2` where it didn't before), add it.

## Common pitfalls

- **`--strict` audit failures on a bump**: Upstream may have introduced new audit-triggering patterns (e.g. dropped a `LICENSE` file, changed a path). Investigate before suppressing.
- **Resource bloat in Python bumps**: `brew update-python-resources` may add 30 new resources because a transitive dep grew. Verify the resources are real, not malware/typo-squatting.
- **Sha256 changes for the same tag**: GitHub auto-generated tarballs are stable, but if upstream re-pushes a tag, the sha256 changes. This is a security flag — ask upstream what changed.
- **Bumping a formula that's now in homebrew-core**: If `brew search <name>` shows the tool is now in homebrew-core, propose to the user that we delete the formula from our tap and let them use core.

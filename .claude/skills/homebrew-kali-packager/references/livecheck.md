# Livecheck blocks

`livecheck` tells Homebrew where to look for new versions of a formula. **Always include a livecheck block** unless the URL is on a service Homebrew can't auto-detect.

## When you don't need a `livecheck` block

For these URL patterns, Homebrew has built-in strategies and `livecheck` is automatic:

- `https://github.com/<user>/<repo>/archive/refs/tags/v<version>.tar.gz` → uses GitHub releases
- `https://files.pythonhosted.org/...` → uses PyPI
- `https://www.cpan.org/...` or `cpan.metacpan.org` → uses CPAN
- `https://crates.io/...` → uses crates.io

## When you do need a `livecheck` block

- `git` URLs without proper releases (pinned to commit SHAs)
- GitLab releases
- Custom download pages (vendor websites)
- GitHub repos that use `master`/`main` instead of releases for stable versions

## GitLab releases

```ruby
livecheck do
  url "https://gitlab.com/kalilinux/packages/<package>/-/releases"
  regex(/<package>[._-]v?(\d+(?:\.\d+)+)/i)
end
```

Or use the GitLab API:

```ruby
livecheck do
  url "https://gitlab.com/api/v4/projects/<id>/releases"
  strategy :json do |json|
    json.map { |r| r["tag_name"][/(\d+(?:\.\d+)+)/, 1] }
  end
end
```

## Git tags (when no proper releases exist)

```ruby
livecheck do
  url :stable
  strategy :git
  regex(/^v?(\d+(?:\.\d+)+)$/i)
end
```

This scans `git ls-remote --tags` and pulls versions from tag names. Works for repos that tag releases but don't create GitHub Release objects.

## Vendor download pages

```ruby
livecheck do
  url "https://example.com/downloads"
  regex(/href=.*?tool[._-]v?(\d+(?:\.\d+)+)\.tar\.gz/i)
end
```

Test it:
```bash
brew livecheck --formula ./Formula/<name>.rb
```

If it doesn't return a sensible version, refine the regex.

## Disabling livecheck (rare)

For formulae pinned to a specific commit with no version tracking:

```ruby
livecheck do
  skip "No upstream releases; pinned to a commit"
end
```

Use this sparingly — it means the formula will never auto-bump, and humans must manually update.

## Testing livecheck

```bash
brew livecheck --formula ./Formula/<name>.rb --verbose --debug
```

Output should look like:
```
==> Checking ./Formula/gobuster.rb
gobuster : 3.6.0 ==> 3.7.0
```

If you see `unable to find versions`, your regex is wrong or the URL strategy doesn't fit.

## Common patterns

| Upstream pattern | Strategy |
|---|---|
| GitHub releases | none needed (auto) |
| GitHub tags only (no releases) | `strategy :git` with regex |
| PyPI | none needed (auto) |
| Sourceforge | `url :stable, strategy: :sourceforge` |
| Apache | regex over the dist directory listing |
| Custom HTML page | regex over the page HTML |
| JSON API | `strategy :json` with a block |

## Common pitfalls

- **Greedy regex**: `/(\d+\.\d+\.\d+)/` may match e.g. "v3.6.0" but also "min-3.0.1" elsewhere on the page. Anchor with context: `/tool[._-]v?(\d+\.\d+\.\d+)/`.
- **Pre-release tags**: `livecheck` will pick `v4.0.0-rc1` if it's there. Add `\d+(?:\.\d+)+/i` (no hyphen) and exclude pre-release suffixes.
- **Date-based versions** (e.g. `2024.11.15`): work fine with `(\d+(?:\.\d+)+)`.

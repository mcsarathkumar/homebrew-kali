# `brew audit` errors and how to fix them

`brew audit --strict --new --formula <path>` must pass before any formula is committed. Here are the common errors and their fixes.

## Always run

```bash
brew audit --strict --new --formula ./Formula/<name>.rb
brew style --fix ./Formula/<name>.rb   # auto-fix style issues
```

`brew style --fix` rewrites the file to match Homebrew's `rubocop` rules. Run it before committing.

## Common errors

### `Formula should have a desc (Description) field`

Add a `desc` line. Keep it under 80 chars, no trailing period, doesn't start with the formula name.

❌ `desc "gobuster is a directory busting tool."`
✅ `desc "Directory/file, DNS and VHost busting tool written in Go"`

### `Description shouldn't include the formula name`

Strip the name from the description.

### `Description shouldn't end with a full stop`

Remove the trailing `.`.

### `Versioned formulae should be in <name>@<version>.rb files`

If you have e.g. two versions of a tool, the older one goes in `tool@1.rb` with `class ToolAT1 < Formula`. Don't put two formulae in one file.

### `License must be a valid SPDX identifier`

Use exact SPDX strings: `MIT`, `Apache-2.0`, `GPL-3.0-only`, `GPL-3.0-or-later`, `BSD-3-Clause`. See https://spdx.org/licenses/.

For dual licenses:
```ruby
license any_of: ["MIT", "Apache-2.0"]
```

For all-of:
```ruby
license all_of: ["GPL-2.0-only", "Linux-syscall-note"]
```

### `GitHub URL should use https://github.com/.../archive/refs/tags/...`

Don't use `releases/download/v.../source.tar.gz` for GitHub-generated source archives. Use the canonical archive URL:

```ruby
url "https://github.com/<owner>/<repo>/archive/refs/tags/v#{version}.tar.gz"
```

### `head should use the default branch`

```ruby
head "https://github.com/<owner>/<repo>.git", branch: "main"
```

(Or `branch: "master"` if that's what upstream uses.) Don't omit `branch:` — audit complains.

### `Stable URL/checksums must not be inside on_macos/on_linux blocks`

The main `url` + `sha256` must be at the top level. Per-platform variants go inside `on_*` blocks but only as additions.

### `Use OS.mac? instead of MACOS` / `Use Hardware::CPU.arm? instead of ARCH == 'arm64'`

Don't reach for raw constants. Use the helpers:
- `OS.mac?` / `OS.linux?`
- `Hardware::CPU.arm?` / `Hardware::CPU.intel?`
- `MacOS.version >= :sonoma`

Even better, use `on_macos` / `on_linux` / `on_arm` / `on_intel` blocks.

### `depends_on order`

Alphabetical. Build deps with `=> :build` before runtime deps:

❌
```ruby
depends_on "openssl@3"
depends_on "cmake" => :build
depends_on "libpcap"
```

✅
```ruby
depends_on "cmake" => :build
depends_on "libpcap"
depends_on "openssl@3"
```

### `Test should be more comprehensive`

Don't just `system bin/"foo", "--version"`. Add an assertion:

❌
```ruby
test do
  system bin/"foo", "--version"
end
```

✅
```ruby
test do
  assert_match version.to_s, shell_output("#{bin}/foo --version")
end
```

### `Use shell_output instead of backticks`

❌ `output = `#{bin}/foo --version``
✅ `output = shell_output("#{bin}/foo --version")`

### `URL should not include "latest"`

```ruby
# Bad: url "https://github.com/.../releases/latest/download/foo.tar.gz"
# Good: url "https://github.com/.../archive/refs/tags/v#{version}.tar.gz"
```

### `Don't use sudo, su, etc.`

Never. If a tool genuinely needs root at runtime (e.g. `nmap` with raw sockets), the user runs it with `sudo` themselves. Don't bake that into the formula.

### `Manpages should be installed`

If upstream ships a manpage, install it:
```ruby
man1.install "docs/foo.1"
# or for multiple:
man1.install Dir["docs/*.1"]
```

### `Custom version is required`

If `brew create` couldn't infer the version from the URL, you must declare it:
```ruby
version "1.2.3"
```

This is also needed when pinning to a git commit.

## Style errors (run `brew style --fix`)

Most of these auto-fix:
- Trailing whitespace
- Wrong quote style (Homebrew prefers `"` over `'`)
- Hash rocket vs. modern syntax (`:foo => "bar"` → `foo: "bar"`)
- Indentation (2 spaces, no tabs)
- Line length (max 118 chars)

If `brew style --fix` doesn't fix it, the violation is structural — look at the actual error.

## When audit is just wrong

Very rarely, `audit` has a false positive. Look for similar formulae in homebrew-core that have the same pattern — if they pass, find the exception. If you genuinely need to suppress, add `# rubocop:disable Style/...` comments narrowly. **Don't blanket-disable.**

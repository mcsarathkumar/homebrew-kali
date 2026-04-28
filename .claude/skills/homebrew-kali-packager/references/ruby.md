# Ruby formulae

Use this for Ruby gems and Ruby-based CLI tools. Examples in homebrew-core: `wpscan`, `cewl`, `whatweb`, `evil-winrm`.

## Standard template

```ruby
class Wpscan < Formula
  desc "Black box WordPress vulnerability scanner"
  homepage "https://wpscan.com/wordpress-security-scanner"
  url "https://github.com/wpscanteam/wpscan/archive/refs/tags/v3.8.28.tar.gz"
  sha256 "REPLACE_WITH_REAL_SHA256"
  license "MIT-Modern-Variant"

  depends_on "pkgconf" => :build
  depends_on "libffi"
  depends_on "libyaml"
  depends_on "openssl@3"
  depends_on "ruby"

  uses_from_macos "zlib"

  def install
    ENV["GEM_HOME"] = libexec
    system "gem", "build", "wpscan.gemspec"
    system "gem", "install", "wpscan-#{version}.gem"

    bin.install libexec/"bin/wpscan"
    bin.env_script_all_files(libexec/"bin", GEM_HOME: ENV["GEM_HOME"])
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/wpscan --version")
  end
end
```

## Key points

- **`depends_on "ruby"`** — Use Homebrew's Ruby, not system Ruby.
- **`GEM_HOME = libexec`** — Install gems into the formula's `libexec`, not globally.
- **`bin.env_script_all_files`** — Wraps the binary in a shell script that sets `GEM_HOME` correctly. Without this, the tool won't find its gems at runtime.
- **`pkgconf` (not `pkg-config`)** — homebrew-core renamed this. Always use `pkgconf`.

## Single-file Ruby scripts

For small tools that are just a single `.rb` file (not a proper gem), consider:

```ruby
def install
  libexec.install Dir["*"]
  (bin/"<tool>").write_env_script libexec/"<tool>.rb",
    PATH:    "#{Formula["ruby"].opt_bin}:$PATH"
end
```

## Bundler-based projects

If upstream uses `Gemfile`/`Gemfile.lock`:

```ruby
def install
  ENV["GEM_HOME"] = libexec
  ENV["BUNDLE_PATH"] = libexec

  system "bundle", "config", "set", "--local", "path", libexec
  system "bundle", "install", "--standalone", "--without=development", "test"
  # ...
end
```

This is fiddlier — find a similar formula in homebrew-core (e.g. `wpscan`, `metasploit` if it ever lands there) and mirror it.

## Test patterns

```ruby
test do
  assert_match version.to_s, shell_output("#{bin}/<tool> --version")
end
```

## Common pitfalls

- **Native gem extensions**: Gems like `nokogiri`, `ffi`, `eventmachine` build native code. Make sure the right `depends_on` is in place (`libxml2`, `libxslt`, `libffi`, `openssl@3`).
- **System Ruby is too old**: Always `depends_on "ruby"` — never rely on `/usr/bin/ruby`.
- **PATH leakage**: Without `bin.env_script_all_files`, the tool may pick up the wrong gems. Always wrap.

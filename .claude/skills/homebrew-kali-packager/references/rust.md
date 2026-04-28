# Rust formulae

Use this for any tool whose upstream is a Cargo project (look for `Cargo.toml`). Examples in homebrew-core: `feroxbuster`, `bat`, `ripgrep`, `rustscan`, `caido-cli`.

## Standard template

```ruby
class Feroxbuster < Formula
  desc "Fast, simple, recursive content discovery tool"
  homepage "https://github.com/epi052/feroxbuster"
  url "https://github.com/epi052/feroxbuster/archive/refs/tags/v2.11.0.tar.gz"
  sha256 "REPLACE_WITH_REAL_SHA256"
  license "MIT"
  head "https://github.com/epi052/feroxbuster.git", branch: "main"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    generate_completions_from_executable(bin/"feroxbuster", "--completions")
  end

  test do
    output = shell_output("#{bin}/feroxbuster --version")
    assert_match version.to_s, output
  end
end
```

## Key points

- **`depends_on "rust" => :build`** — Rust toolchain at build time only. Binaries are mostly static (libc is dynamic on macOS, but that's fine).
- **`std_cargo_args`** — Expands to `--locked --root #{prefix} --path .`. Use this; don't roll your own.
- **`Cargo.lock`**: Verify upstream commits a `Cargo.lock` to the tag. `--locked` requires it. If upstream has no `Cargo.lock`, drop `--locked` (acceptable but flag this to the user as suboptimal).

## Workspace projects

If the repo is a Cargo workspace and you need a specific package:

```ruby
def install
  system "cargo", "install", *std_cargo_args(path: "crates/cli")
end
```

Or to build a specific binary from a workspace:

```ruby
def install
  system "cargo", "install", *std_cargo_args, "--bin", "tool-cli"
end
```

## OpenSSL / native deps

Rust crates often link against OpenSSL via the `openssl-sys` crate. On macOS this usually works because Homebrew's openssl is on `PKG_CONFIG_PATH`, but you may need:

```ruby
depends_on "openssl@3"
depends_on "pkgconf" => :build
```

For crates using `rustls` (pure-Rust TLS) you don't need OpenSSL. Check upstream's `Cargo.toml` for the `tls` feature.

## Native libraries (libpcap, libgit2, etc.)

```ruby
depends_on "libgit2"
# or
depends_on "libpcap"
```

For libpcap on macOS, the system version usually works — only declare it as a dep if upstream's build script needs the headers from a specific version.

## Shell completions

Many Rust CLIs use `clap` and emit completions via `--completions <shell>` or `--generate-completion <shell>`:

```ruby
generate_completions_from_executable(bin/"feroxbuster", "--completions")
```

If upstream pre-generates completions in a `completions/` directory:

```ruby
bash_completion.install "completions/feroxbuster.bash"
zsh_completion.install "completions/_feroxbuster"
fish_completion.install "completions/feroxbuster.fish"
```

## Test patterns

```ruby
test do
  assert_match version.to_s, shell_output("#{bin}/feroxbuster --version")
  # Test that it fails gracefully without a target
  output = shell_output("#{bin}/feroxbuster --no-scan 2>&1", 1)
  assert_match "url", output.downcase
end
```

## Common pitfalls

- **Apple Silicon vs Intel build differences**: Rust handles this well, but some crates with C dependencies fail on one arch. Test on both if you have access.
- **Nightly Rust requirement**: Refuse to package crates that need nightly. They won't build with Homebrew's stable Rust.
- **`build.rs` shenanigans**: Some crates run code at build time that downloads things. This will fail in Homebrew's sandboxed build. Patch or refuse.
- **`cargo install` vs `cargo build --release`**: Always use `cargo install` with `std_cargo_args` for binaries. It handles installation paths correctly.

# Prebuilt binary releases

Use this when upstream ships precompiled macOS binaries (usually for Go, Rust, or Java tools), and building from source is impractical or upstream's official distribution method is the binary. Examples: `caido` (Rust binary), `ghidra` (Java), `burpsuite` (commercial — see `cask.md`).

**Prefer building from source whenever possible.** Use this pattern only when:
- Upstream doesn't ship source for redistribution
- The build is genuinely too complex (e.g. Ghidra's full Java + Gradle build)
- Upstream's official "install on Mac" is "download and unzip this binary"

## Standard template

```ruby
class Caido < Formula
  desc "Lightweight web security auditing toolkit"
  homepage "https://caido.io/"
  version "0.47.0"
  license "EULA"  # commercial — see notes below

  on_macos do
    on_arm do
      url "https://caido.io/releases/v0.47.0/caido-cli-v0.47.0-mac-aarch64.tar.gz"
      sha256 "REPLACE_WITH_REAL_SHA256"
    end
    on_intel do
      url "https://caido.io/releases/v0.47.0/caido-cli-v0.47.0-mac-x86_64.tar.gz"
      sha256 "REPLACE_WITH_REAL_SHA256"
    end
  end

  on_linux do
    on_intel do
      url "https://caido.io/releases/v0.47.0/caido-cli-v0.47.0-linux-x86_64.tar.gz"
      sha256 "REPLACE_WITH_REAL_SHA256"
    end
  end

  def install
    bin.install "caido-cli" => "caido"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/caido --version")
  end
end
```

## Key points

- **Per-arch URLs**: macOS arm64 (`on_arm`) and Intel (`on_intel`) usually need different binaries. Use nested `on_macos`/`on_arm` blocks.
- **Multiple sha256s** — one per platform.
- **Don't bundle a Linux binary on macOS.** The `on_linux` block above only matters if you want the same formula to work on Homebrew-on-Linux.

## License caveat

Homebrew requires a known license. For commercial tools that publish binaries with EULAs:

- If the EULA permits redistribution by package managers: `license :cannot_represent` or use an SPDX-shorthand for "proprietary" (`license "EULA"` is not standard — check `https://spdx.org/licenses/`).
- If the EULA *doesn't* permit redistribution: do not package as a formula. Use a cask that downloads from upstream (`cask.md`), or refuse.

For Kali tools, almost everything is open source — this section is mostly about edge cases.

## Versioned URLs

Make sure the URL contains the version so `livecheck` can detect new releases. Bad:

```ruby
url "https://example.com/latest/tool-mac-arm64.tar.gz"  # no version, can't bump
```

Good:

```ruby
url "https://example.com/v#{version}/tool-#{version}-mac-arm64.tar.gz"
```

## When the binary needs unsigning / quarantine bypass

macOS Gatekeeper will block unsigned binaries. **Do NOT** add `xattr -d com.apple.quarantine` or codesigning workarounds in a formula — that's user-hostile. Either:
- File a bug upstream asking them to ship signed/notarized binaries
- Switch to a cask (which has proper Gatekeeper handling)
- Build from source

## Test pattern

```ruby
test do
  assert_match version.to_s, shell_output("#{bin}/<tool> --version")
end
```

## Common pitfalls

- **No arm64 binary upstream**: If upstream only ships x86_64, you'll need to either build from source for arm64 or document that arm64 users need Rosetta. The latter is a poor user experience — push upstream for native arm64.
- **Stripped binaries**: Already stripped, good. If the binary is huge (e.g. Ghidra), use a `cask` instead.
- **Dynamic library paths baked in**: Some prebuilt binaries hardcode `/usr/local/lib/...` and break on Apple Silicon (where Homebrew prefix is `/opt/homebrew`). If you see `dyld` errors, you may need to `install_name_tool -change` the embedded paths in the install method.

# Casks (GUI apps, .dmg, .pkg)

Use a cask when:
- The tool is a macOS GUI app distributed as `.dmg` or `.app.zip`
- The tool is a `.pkg` installer
- Upstream's official "install on Mac" is "drag this to Applications"

Examples: `burpsuite`, `wireshark` (the GUI), `ghidra`, `bloodhound` (the GUI desktop app).

**For CLI tools, always prefer a formula.** Casks are for proper macOS apps with `.app` bundles.

## Casks live in a separate directory

In your tap, casks go in `Casks/` (not `Formula/`). The directory layout:

```
mcsarathkumar/homebrew-kali/
├── Formula/
│   ├── gobuster.rb
│   └── feroxbuster.rb
└── Casks/
    └── caido.rb
```

## Standard cask template (.dmg with .app)

```ruby
cask "burpsuite" do
  version "2025.10.1"
  sha256 "REPLACE_WITH_REAL_SHA256"

  url "https://portswigger-cdn.net/burp/releases/download?product=community&version=#{version}&type=MacOsArm64"
  name "Burp Suite Community Edition"
  desc "Web vulnerability scanner and proxy"
  homepage "https://portswigger.net/burp/communitydownload"

  livecheck do
    url "https://portswigger.net/burp/releases/data?lastId=99999&pageSize=1"
    regex(/community.*?(\d+(?:\.\d+)+)/i)
  end

  app "Burp Suite Community Edition.app"

  zap trash: [
    "~/.BurpSuite",
    "~/Library/Preferences/com.portswigger.BurpSuiteCommunity.plist",
  ]
end
```

## Key cask differences from formulae

- **No `class` keyword**: cask "name" do ... end (lowercase, in quotes).
- **No `def install`**: declarative stanzas (`app`, `binary`, `pkg`, etc.) handle installation.
- **`app "Foo.app"`** moves the app bundle into `/Applications` (or `~/Applications`).
- **`zap`** declares files to remove on `brew uninstall --zap` (not `brew uninstall`).
- **`livecheck`** is similar to formulae.

## Per-architecture downloads

```ruby
cask "ghidra" do
  arch arm: "arm64", intel: "x86_64"

  version "11.2.0"
  sha256 arm:   "REPLACE_WITH_ARM_SHA256",
         intel: "REPLACE_WITH_INTEL_SHA256"

  url "https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_#{version}_build/ghidra_#{version}_PUBLIC_#{arch}.zip"
  name "Ghidra"
  desc "Software reverse engineering framework"
  homepage "https://github.com/NationalSecurityAgency/ghidra"

  app "ghidra_#{version}_PUBLIC/Ghidra.app"  # if upstream ships an app bundle
  # OR for CLI-style ghidra:
  binary "ghidra_#{version}_PUBLIC/ghidraRun", target: "ghidra"
end
```

## .pkg installers

```ruby
cask "tool-name" do
  version "1.2.3"
  sha256 "..."
  url "https://example.com/tool-#{version}.pkg"
  name "Tool"
  desc "..."
  homepage "..."

  pkg "tool-#{version}.pkg"

  uninstall pkgutil: "com.example.tool"
end
```

`pkgutil --pkgs` on macOS shows the bundle IDs of installed packages — use that to find the right `uninstall pkgutil:` value.

## Casks with both GUI and CLI

If upstream ships an `.app` that contains a CLI tool inside:

```ruby
app "Caido.app"
binary "#{appdir}/Caido.app/Contents/MacOS/caido-cli", target: "caido"
```

This installs the GUI to `/Applications` AND symlinks the CLI to `/opt/homebrew/bin/caido`.

## Test for casks

Casks don't have `test do` blocks like formulae. Verification is mostly via `brew audit --cask`:

```bash
brew audit --new --cask ./Casks/<name>.rb
brew install ./Casks/<name>.rb
brew uninstall <name>
```

## Common pitfalls

- **Wrong `app` name**: the `app` stanza must match the exact `.app` bundle name in the .dmg. Mount the .dmg manually and `ls /Volumes/<mount>/` to confirm.
- **Stale livecheck URLs**: Many vendor download pages move. Test livecheck with `brew livecheck --cask <name>`.
- **Arch detection**: Some tools have `aarch64` vs `arm64` naming differences. Match what upstream uses.
- **Sparkle feeds**: For apps that auto-update via Sparkle, `livecheck strategy: :sparkle` works — see Homebrew Cask docs.
- **`zap` vs `uninstall`**: `uninstall` runs always; `zap` only with `--zap`. For sensitive tools, put preference plists in `zap` so users keep config across reinstalls.

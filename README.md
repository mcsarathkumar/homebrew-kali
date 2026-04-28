# homebrew-kali

A Homebrew tap that brings Kali Linux security tools — and other Linux-only Debian/RPM packages — to macOS.

## Install the tap

```bash
brew tap mcsarathkumar/kali https://github.com/mcsarathkumar/homebrew-kali
```

## Install a tool

```bash
brew install mcsarathkumar/kali/<formula>
```

## Available formulae

| Formula | Description | Upstream |
|---|---|---|
| [`seclists`](Formula/seclists.rb) | Collection of wordlists used during security assessments | [danielmiessler/SecLists](https://github.com/danielmiessler/SecLists) |

## Usage examples

### SecLists

After `brew install mcsarathkumar/kali/seclists`, wordlists live under `$(brew --prefix)/share/seclists/`:

```bash
ffuf    -w "$(brew --prefix)/share/seclists/Discovery/Web-Content/common.txt" \
        -u https://example.com/FUZZ

gobuster dir \
        -w "$(brew --prefix)/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt" \
        -u https://example.com
```

## Contributing

Formulae in this tap follow official Homebrew conventions:

- Class name is the strict CamelCase of the filename (`feroxbuster.rb` → `class Feroxbuster`)
- License is a valid SPDX identifier
- Every formula has a meaningful `test do` block
- All formulae pass `brew audit --strict --new` before being committed

To add or update a formula, work on a feature branch, run `brew install --build-from-source`, `brew test`, and `brew audit --strict --new`, and open a PR.

## License

Tap files are MIT-licensed (see [LICENSE](LICENSE)). Each upstream tool retains its own license.

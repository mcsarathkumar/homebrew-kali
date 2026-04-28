# Finding upstream sources for Kali tools

Kali tools come from many upstream repos. The chain is:

```
User says: "package gobuster"
  ↓
Kali tool page: https://www.kali.org/tools/gobuster/
  ↓ (has "Source Project" link)
Upstream: https://github.com/OJ/gobuster
  ↓ (has tagged releases)
Tarball URL: https://github.com/OJ/gobuster/archive/refs/tags/v3.6.0.tar.gz
```

## Step-by-step lookup

### Step 1: Visit the Kali tool page

```
https://www.kali.org/tools/<name>/
```

This page shows:
- The "Source Project" link (clickable archive icon at top)
- The package name(s) in Debian/Kali (used for `apt install ...`)
- The commands the package provides
- A short description and example usage

### Step 2: Follow the Source Project link

It usually goes to GitHub or GitLab. From there:
- Check `Releases` for tagged versions
- Check `Tags` if no Releases
- Check `Cargo.toml` / `go.mod` / `setup.py` / `package.json` for build system
- Check `LICENSE` for SPDX license

### Step 3: Cross-check with Kali's GitLab packaging

```
https://gitlab.com/kalilinux/packages/<name>
```

This holds Kali's Debian packaging (the `debian/` directory and any patches Kali applies on top of upstream). Useful for:
- **Patches Kali applies** that may also be needed on macOS
- **Dependency list** in `debian/control` (gives hints about runtime deps)
- **Build commands** in `debian/rules` (if it deviates from upstream's `make install`)

You usually don't need to use Kali's packaging directly — the upstream source is what we package. But check `debian/patches/` for fixes that might apply.

## Mapping Kali package name → upstream

Most Kali tool names match upstream, but watch for these patterns:

| Kali name | Upstream |
|---|---|
| `python3-<name>` | A Python lib; the CLI is usually `<name>` |
| `lib<name>-dev` | A dev headers package; usually maps to a C library — find the CLI in a sibling package |
| `<name>-utils` | The user-facing tools shipped alongside a library |
| `kali-tools-<category>` | A meta-package — many tools, not one. Don't try to "package this"; package members individually |

## When upstream doesn't exist or is dead

Some Kali tools are forks maintained only by Kali:
- Check the source link on `kali.org/tools/<name>/` — does it go to `gitlab.com/kalilinux/packages/<name>`?
- If yes, that IS the upstream. Use that as the formula's `homepage` and `url`.

For tools that have been abandoned upstream but Kali still ships:
- Pin to the latest Kali commit
- Add a comment in the formula: `# Upstream is dormant. Tracking Kali's fork.`

## Quick web-search checklist

When the user gives you a tool name, before writing anything:

```
1. Search: "site:kali.org/tools/ <name>"  → confirms it's a Kali tool
2. Search: "<name> github" or "<name> gitlab"  → finds upstream
3. Visit upstream → check Releases, Tags, License, build system
4. Search: "site:github.com/Homebrew/homebrew-core <name>" → check if already in core
```

If step 4 finds it in homebrew-core and the version matches what the user wants, **stop**. Tell the user:
> `<name>` is already in homebrew-core at version X.Y.Z. You can `brew install <name>` directly without using a tap. Want me to package it anyway, or use core?

## Common Kali tool examples

| Tool | Upstream | Build | Notes |
|---|---|---|---|
| `gobuster` | github.com/OJ/gobuster | Go | Already in homebrew-core |
| `feroxbuster` | github.com/epi052/feroxbuster | Rust | Already in homebrew-core |
| `subfinder` | github.com/projectdiscovery/subfinder | Go | Already in homebrew-core |
| `nuclei` | github.com/projectdiscovery/nuclei | Go | Already in homebrew-core |
| `naabu` | github.com/projectdiscovery/naabu | Go (CGO with libpcap) | Already in homebrew-core |
| `httpx` | github.com/projectdiscovery/httpx | Go | Already in homebrew-core |
| `ffuf` | github.com/ffuf/ffuf | Go | Already in homebrew-core |
| `amass` | github.com/owasp-amass/amass | Go | Already in homebrew-core |
| `hashcat` | github.com/hashcat/hashcat | C/Make | Already in homebrew-core |
| `john` | github.com/openwall/john | C/autotools | Already in homebrew-core (as `john-jumbo`) |
| `nmap` | github.com/nmap/nmap | C/autotools | Already in homebrew-core |
| `aircrack-ng` | github.com/aircrack-ng/aircrack-ng | C/autotools | Already in homebrew-core, with caveats about Wi-Fi monitor mode |
| `theHarvester` | github.com/laramies/theHarvester | Python | Already in homebrew-core (as `theharvester`) |
| `dnsenum` | github.com/SparrowOf/dnsenum | Perl | Not in core |
| `wpscan` | github.com/wpscanteam/wpscan | Ruby | Already in homebrew-core |
| `sqlmap` | github.com/sqlmapproject/sqlmap | Python | Already in homebrew-core |

**Many top Kali tools are already in homebrew-core.** Always check first. The tap is for tools that *aren't* in core or where the user wants something Kali-specific.

## Tools that genuinely need the tap (not in core)

These are commonly requested but not in homebrew-core, making them good tap candidates:

- `bloodhound.py` (Python AD enumeration)
- `bloodyAD`
- `crackmapexec` / `netexec` (NetExec is the active fork)
- `enum4linux-ng`
- `evil-winrm-py` (Python port of evil-winrm)
- `impacket-scripts`
- `kerberoast`
- `mitm6`
- `pwncat`
- `responder`
- `roadtools`
- Various Kali-internal forks of older tools

For each, follow the workflow in the matching `references/<lang>.md` file.

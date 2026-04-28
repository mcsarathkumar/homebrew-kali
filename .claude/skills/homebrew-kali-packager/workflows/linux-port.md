# Workflow: Port a Linux-only apt/rpm tool to macOS

When the user says something like "I use `<tool>` on Kali, make me a Homebrew formula" or "this tool is only in apt — port it".

## Stage 0 — Reconnaissance (extra careful)

Before doing anything, find out **why** the tool isn't already on macOS. Three possibilities:

### A. It's just packaged for Linux distros, but the source builds fine on macOS

Examples: many small Python/Perl scripts, most Go/Rust tools.

→ Just follow the new-formula workflow. The "Linux-only" framing was misleading.

### B. It uses some Linux features but most of it is portable

Examples: tools using `libcap`, optional `/proc` paths, `iptables` glue.

→ Follow new-formula workflow with conditional logic. See `references/linux-only-tools.md`.

### C. It's fundamentally Linux-only

Examples: kernel-based tools (eBPF, kernel modules), Wi-Fi monitor mode tools dependent on `nl80211`, anything that loads or talks to a Linux kernel module.

→ Refuse to package as a formula. Suggest Docker/VM. See `references/linux-only-tools.md`.

## Stage 1 — Detect which category

Read upstream's `README` and `INSTALL` for OS support claims. Check the source for:

```bash
# After cloning upstream:
grep -r "linux/" --include="*.c" --include="*.cpp" --include="*.h" .
grep -r "AF_NETLINK\|/proc/\|iptables\|nl80211\|eBPF\|libcap\|sys/capability" .
grep -r "PF_PACKET\|TPACKET\|SO_BINDTODEVICE" .
```

If you see lots of these and they're in the main code path (not an optional module), you're in category C. Otherwise, A or B.

## Stage 2 — For category B, design the macOS port

Pick from the strategies in `references/linux-only-tools.md`:

1. Conditional `on_linux` deps
2. `--disable-<feature>` configure flags
3. Patches with `#ifdef __linux__`
4. Stub functions for unsupported APIs

Show the user your plan before writing code:
> "This tool uses libcap on Linux. On macOS we'd disable that with `--disable-cap` (line 47 of upstream's `configure.ac`) and the tool will lose the ability to drop privileges, but core functionality works. Sound good?"

## Stage 3 — Then go to the new-formula workflow

Once you know the build system and what to disable/patch, read the matching language reference and follow `workflows/new-formula.md`.

## Stage 4 — Document limitations

Always add a `caveats` block when the macOS port loses functionality:

```rbex
def caveats
  <<~EOS
    This tool was originally Linux-only. The macOS build has the following limitations:
      * <feature1>: not supported on macOS (no equivalent kernel API)
      * <feature2>: limited to <subset> of behavior
    For full functionality, run inside a Kali Linux VM or Docker container.
  EOS
end
```

Users see this on `brew install <name>` and `brew info <name>`.

## Stage 5 — Test on both arches

If you have access:
- arm64 macOS (Apple Silicon)
- x86_64 macOS (Intel)

Many Linux-derived tools have hand-rolled assembly that breaks on arm64. If you can't test both, flag this to the user:
> "I've only tested on arm64. The formula should work on Intel too but please verify on a Mac you have access to."

## Stage 6 — Refusing gracefully (category C)

If the tool is fundamentally Linux-only, your response should be:

> I can't produce a working Homebrew formula for `<tool>` because it depends on `<linux-feature>`, which has no macOS equivalent. Specifically, it uses `<details>`.
>
> Your best options are:
> 1. **Docker**: `docker run --rm -it kalilinux/kali-rolling bash` then `apt update && apt install <tool>`
> 2. **Kali VM**: Install Kali in UTM (Apple Silicon) or VirtualBox/VMware Fusion (Intel)
> 3. **Remote Kali**: SSH to a cloud Kali instance
>
> Would you like help setting up any of these?

Don't try to force a formula that fundamentally won't work — it'll waste time and frustrate the user when nothing runs.

## Examples of refusal cases

- **Wi-Fi monitor-mode-only tools** (airodump-ng standalone use, fluxion, wifiphisher, eaphammer): macOS built-in Wi-Fi can't reliably go into monitor mode.
- **eBPF-based tools** (bpftrace, BCC tools, tetragon, falco): no eBPF on macOS.
- **Kernel module tools** (rkhunter aspects, some rootkit detectors): can't load Linux modules.
- **`iptables`-based tools that orchestrate firewall rules**: `pf` is different enough that a clean port is a project, not a formula.
- **systemd-tied tools**: launchd is different.

## Examples of "actually portable" tools that look Linux-only

- Most Python tools (sqlmap, theHarvester, dnsrecon) — already portable
- Most Go tools (gobuster, subfinder, ffuf) — portable
- Most Rust tools (feroxbuster, rustscan) — portable
- Most Perl scripts (dnsenum, nikto) — portable, just need CPAN deps
- Many C tools that are "Linux-distributed" but POSIX-clean (fcrackzip, hashid, hydra-without-pam): portable with minor patches

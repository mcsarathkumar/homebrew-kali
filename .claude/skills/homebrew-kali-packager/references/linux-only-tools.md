# Porting Linux-only tools to macOS

Many Kali tools are Linux-only because they use:
- Raw netlink sockets (`AF_NETLINK`)
- BPF / eBPF programs
- `/proc` filesystem
- Linux capability system (`libcap`)
- `iptables` / `nftables`
- Wireless `nl80211` interfaces (Wi-Fi monitor mode)
- USB raw access via `usbfs`
- Kernel modules

Some of these have macOS equivalents; some don't.

## Decision tree

```
Is the tool fundamentally tied to a Linux kernel feature?
├── Yes (e.g. needs eBPF, Wi-Fi monitor mode via nl80211, kernel module)
│   └── Refuse. Tell the user it cannot reasonably run on macOS.
│       Suggest: Run Kali in a VM or container.
│
├── Partially (most code is portable, some Linux paths)
│   └── Patch or guard. See "Conditional code" below.
│
└── No (just happened to be packaged for Debian/RPM)
    └── Package normally. The "Linux-only" framing was misleading.
```

## Conditional code strategies

### Strategy 1: `on_linux` for Linux-only deps

```rbex
on_linux do
  depends_on "libcap"
  depends_on "linux-headers"
end
```

If the tool builds without these on macOS (just losing some features), this is enough.

### Strategy 2: Configure flags

If upstream supports `--disable-<feature>`:

```rbex
def install
  args = std_configure_args
  args << "--disable-cap" if OS.mac?
  args << "--disable-netlink" if OS.mac?
  system "./configure", *args
  system "make", "install"
end
```

### Strategy 3: Patches

Last resort. Add to the formula:

```rbex
# Skip Linux-specific code paths on macOS
patch :DATA

__END__
diff --git a/src/main.c b/src/main.c
@@ -10,7 +10,11 @@
+#ifdef __linux__
 #include <sys/capability.h>
+#endif
```

**Always upstream the patch too.** Open a PR with the same change.

### Strategy 4: Stub functions

If the tool calls a Linux-specific API but only uses it for an optional feature:

```c
#ifdef __APPLE__
static int do_linux_thing(void) { return -ENOTSUP; }
#endif
```

Patch this in via `inreplace` or a `patch` block.

## Common Linux-isms and their macOS equivalents

| Linux | macOS equivalent | Notes |
|---|---|---|
| `/proc/<pid>/cmdline` | `proc_pidpath()` (libproc) | Different API; needs source patch |
| `epoll` | `kqueue` | Same idea, different syscalls |
| `inotify` | `FSEvents` / `kqueue` | Different APIs |
| `iptables` | `pfctl` | Both work for packet filtering, totally different syntax |
| `tun/tap` (`/dev/net/tun`) | `utun` device + `pf` | utun is built-in on macOS |
| Raw sockets | Raw sockets work on macOS too, but require root | Same syscall, similar caveats |
| `libpcap` | `libpcap` | Works the same, ships with macOS |
| `libcap` (capabilities) | No equivalent | Just disable on macOS |
| `nl80211` (Wi-Fi monitor) | `airport -s` for scan; no monitor mode without external adapter | Big limitation for wifi tools |
| `dbus` | dbus exists but rarely used; macOS uses XPC | Most security tools don't need dbus on macOS |
| `systemd` services | launchd plists | Use `service do ... end` block in formula |

## When to refuse

Refuse to package and tell the user upfront if:

- The tool's primary purpose is **Wi-Fi monitor-mode attacks** (aircrack-ng works on macOS but with severe limitations; airodump-ng can't put built-in Wi-Fi into monitor mode reliably). Suggest external USB Wi-Fi adapter + Linux VM.
- The tool **directly loads kernel modules** (e.g. some rootkit detection, USB exploitation tools).
- The tool **depends on Linux containers** (`runc`, `crun`, `lxc`).
- The tool requires **eBPF** programs (`bpftool`, `bcc`-based tools, `tetragon`).

For these, your response should be:
> This tool relies on Linux kernel features that don't exist on macOS. I'd recommend running it inside Docker (`docker run kalilinux/kali-rolling`) or a Kali VM. I can help you set that up, but I can't produce a working Homebrew formula.

## Documenting limitations

When a port works but with reduced functionality, add a `caveats` block:

```rbex
def caveats
  <<~EOS
    Note: This tool was originally Linux-only. The macOS port has some limitations:
      * Wi-Fi monitor mode is not supported on the built-in adapter.
        Use an external USB adapter with a Linux-compatible chipset
        (then run from Linux — not supported on macOS).
      * The --capabilities flag is a no-op on macOS.
  EOS
end
```

Users see this on `brew install` and `brew info`.

## Patch hygiene

When patching to make Linux-only code build on macOS:

1. **Make patches as small as possible.** Wrap in `#ifdef __linux__` rather than removing code.
2. **Test on both arm64 and x86_64.**
3. **Submit upstream.** Reference the upstream PR/issue in a comment.
4. **Don't fork the project.** That's not Homebrew's job; it's a maintenance disaster.

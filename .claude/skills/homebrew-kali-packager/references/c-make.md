# C / C++ formulae (Make, CMake, autotools, Meson)

Use this for tools written in C/C++ that build with `make`, `cmake`, `./configure && make`, or Meson. Examples: `nmap`, `aircrack-ng`, `hashcat`, `john`, `hping3`, `tcpdump`.

## Pick your build system

Inspect the upstream repo:

| File present | Build system | Section below |
|---|---|---|
| `configure` or `configure.ac` | autotools | [Autotools](#autotools) |
| `CMakeLists.txt` | CMake | [CMake](#cmake) |
| `Makefile` only | plain Make | [Plain Make](#plain-make) |
| `meson.build` | Meson | [Meson](#meson) |

If multiple are present, pick the one upstream documents in their build instructions.

## Autotools

```rbex
class Hping3 < Formula
  desc "Active network smashing tool"
  homepage "https://www.hping.org/"
  url "https://github.com/antirez/hping/archive/refs/tags/3.0.tar.gz"
  sha256 "REPLACE_WITH_REAL_SHA256"
  license "GPL-2.0-only"

  depends_on "tcl"

  uses_from_macos "libpcap"

  def install
    system "./configure", "--no-tcl", "--prefix=#{prefix}"
    system "make"
    bin.install "hping3"
    man8.install "docs/hping3.8"
  end

  test do
    output = shell_output("#{bin}/hping3 --version 2>&1", 0)
    assert_match "hping3", output
  end
end
```

For a real autotools project (configure.ac → autoreconf → configure):

```rbex
def install
  system "autoreconf", "--force", "--install", "--verbose"
  system "./configure", *std_configure_args
  system "make", "install"
end
```

`std_configure_args` expands to `--prefix=#{prefix} --disable-debug --disable-dependency-tracking --disable-silent-rules`.

## CMake

```rbex
class Capstone < Formula
  desc "Multi-platform, multi-architecture disassembly framework"
  homepage "https://www.capstone-engine.org/"
  url "https://github.com/capstone-engine/capstone/archive/refs/tags/5.0.3.tar.gz"
  sha256 "REPLACE_WITH_REAL_SHA256"
  license "BSD-3-Clause"

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    # ... compile and run a small program ...
  end
end
```

`std_cmake_args` expands to a sensible set including `-DCMAKE_INSTALL_PREFIX`, `-DCMAKE_BUILD_TYPE=Release`, etc. Don't override these unless you know why.

For build options:
```rbex
system "cmake", "-S", ".", "-B", "build", *std_cmake_args, "-DBUILD_SHARED_LIBS=ON", "-DCAPSTONE_BUILD_TESTS=OFF"
```

## Plain Make

```rbex
class Hashcat < Formula
  desc "World's fastest and most advanced password recovery utility"
  homepage "https://hashcat.net/hashcat/"
  url "https://github.com/hashcat/hashcat/archive/refs/tags/v6.2.6.tar.gz"
  sha256 "REPLACE_WITH_REAL_SHA256"
  license "MIT"

  def install
    system "make", "install", "PREFIX=#{prefix}", "SHARED=1"
  end

  test do
    # ...
  end
end
```

Read the project's `Makefile` to find the right install target and prefix variable. It's usually `PREFIX=` or `DESTDIR=` (or both).

## Meson

```rbex
def install
  system "meson", "setup", "build", *std_meson_args
  system "meson", "compile", "-C", "build", "--verbose"
  system "meson", "install", "-C", "build"
end
```

`std_meson_args` handles prefix, libdir, etc. Add `depends_on "meson" => :build` and `depends_on "ninja" => :build`.

## Common dependencies for security tools

| Need | Homebrew formula |
|---|---|
| Packet capture | `libpcap` (system on macOS — use `uses_from_macos "libpcap"`) |
| OpenSSL | `openssl@3` |
| zlib | `uses_from_macos "zlib"` |
| ncurses | `uses_from_macos "ncurses"` |
| readline | `readline` (Homebrew's, since macOS readline is BSD libedit) |
| pcre/pcre2 | `pcre2` |
| libxml2 | `uses_from_macos "libxml2"` |
| OpenMP (hashcat etc.) | `libomp` (and `depends_on "llvm" => :build` if upstream needs clang's OpenMP) |
| Python bindings | `python@3.12` |

`uses_from_macos` means "use the system one on macOS, our formula on Linux". Use it for things macOS ships natively.

## Linux-specific code

Many security tools have Linux-specific code paths (raw sockets, netlink, /proc). Strategies:

1. **Conditional compile**: If upstream supports it, pass `--disable-<linux-feature>` or similar.
2. **Patch**: For small fixes, use a `patch do ... end` block at end of formula. Always upstream the fix too.
3. **`on_linux` block**: Some deps only apply on Linux:
   ```ruby
   on_linux do
     depends_on "libcap"
   end
   ```
4. **Refuse**: If the tool is fundamentally Linux-only (e.g. needs eBPF), tell the user. See `linux-only-tools.md`.

## Test patterns

```rbex
test do
  assert_match version.to_s, shell_output("#{bin}/<tool> --version")
end
```

For libraries, write a tiny C program in the test block:

```rbex
test do
  (testpath/"test.c").write <<~C
    #include <capstone/capstone.h>
    int main(void) {
      csh handle;
      return cs_open(CS_ARCH_X86, CS_MODE_64, &handle) == CS_ERR_OK ? 0 : 1;
    }
  C
  system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lcapstone", "-o", "test"
  system "./test"
end
```

## Common pitfalls

- **`-Werror` on macOS**: clang on macOS warns about things gcc on Linux doesn't. Sometimes you need to drop `-Werror` from the build or add `ENV.append_to_cflags "-Wno-error=..."`.
- **Apple Silicon arm64 vs Intel x86_64**: Some assembler-heavy projects (hashcat, john) need different flags per arch. Use `Hardware::CPU.arm?` checks or `on_arm` / `on_intel` blocks.
- **Static system libraries**: macOS doesn't ship many static libs. If upstream wants `libfoo.a`, that may need a Homebrew dep that provides static.
- **GNU make extensions**: macOS's BSD tools differ from GNU. If a Makefile uses `$(shell ...)`, GNU sed flags, `--long-flags` to BSD utilities, you may need to `depends_on "gnu-sed"` or similar.

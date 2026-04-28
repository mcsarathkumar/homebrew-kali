# Perl formulae

Use this for Perl scripts and tools. Examples in Kali: `dnsenum`, `nikto`, `dirb`, `cisco-global-exploiter`. Many of these have been around for 15+ years and are essentially "single-script + a handful of CPAN deps".

## Standard template (CPAN deps via resources)

```rbex
class Dnsenum < Formula
  desc "Multithreaded perl script to enumerate DNS information"
  homepage "https://github.com/SparrowOf/dnsenum"
  url "https://github.com/SparrowOf/dnsenum/archive/refs/tags/1.2.6.tar.gz"
  sha256 "REPLACE_WITH_REAL_SHA256"
  license "GPL-2.0-or-later"

  uses_from_macos "perl"

  resource "Net::IP" do
    url "https://cpan.metacpan.org/authors/id/M/MA/MANU/Net-IP-1.26.tar.gz"
    sha256 "..."
  end

  resource "Net::DNS" do
    url "https://cpan.metacpan.org/authors/id/N/NL/NLNETLABS/Net-DNS-1.51.tar.gz"
    sha256 "..."
  end

  # ... more resources ...

  def install
    ENV.prepend_create_path "PERL5LIB", libexec/"lib/perl5"

    resources.each do |r|
      r.stage do
        system "perl", "Makefile.PL", "INSTALL_BASE=#{libexec}"
        system "make"
        system "make", "install"
      end
    end

    libexec.install "dnsenum.pl"
    (bin/"dnsenum").write_env_script libexec/"dnsenum.pl",
      PERL5LIB: ENV["PERL5LIB"]
  end

  test do
    assert_match "dnsenum", shell_output("#{bin}/dnsenum --help 2>&1", 0)
  end
end
```

## Key points

- **`uses_from_macos "perl"`** — macOS ships Perl. Don't pull in our own unless we have to.
- **Per-resource `Makefile.PL` build** — This is the canonical way to install CPAN deps inside a formula's `libexec`.
- **`write_env_script` with `PERL5LIB`** — wraps the script so it can find the deps at runtime.

## Finding CPAN dependencies

For each `use Some::Module;` in the script, find the canonical CPAN distribution:

1. Search at `https://metacpan.org/`.
2. Click the module → "Author" → grab the latest stable distribution tarball URL.
3. URL pattern: `https://cpan.metacpan.org/authors/id/X/XX/XXXX/Some-Module-1.23.tar.gz`.
4. `shasum -a 256 <downloaded tarball>` for the sha256.

You can also use `cpanm --look <Module>` locally to find dependencies and versions, then translate to resources.

## Single-file scripts (no CPAN deps beyond core)

If the script only uses Perl core modules (`Getopt::Long`, `Socket`, etc.):

```rbex
def install
  bin.install "tool.pl" => "tool"
  # Make sure the shebang is right
  inreplace bin/"tool", %r{^#!/usr/bin/env perl}, "#!#{Formula["perl"].opt_bin}/perl" if build.with?("perl")
end
```

For scripts using only system perl, don't even need `inreplace` — keep the `#!/usr/bin/env perl`.

## Test patterns

```rbex
test do
  output = shell_output("#{bin}/<tool> --help 2>&1", 0)  # or exit-code 1 if --help exits 1
  assert_match "<tool>", output
end
```

## Common pitfalls

- **macOS Perl version drift**: `uses_from_macos "perl"` is fine for now, but very old scripts may need exact module versions. Pin the resource versions if you hit incompatibilities.
- **Don't use `cpan` or `cpanm` in the install method.** They try to write to system locations and can hit network. Use `resource` blocks.
- **Shebang lines**: If upstream's script starts with `#!/usr/bin/perl`, don't `inreplace` to `/opt/homebrew/bin/perl` — use `#!/usr/bin/env perl` instead.

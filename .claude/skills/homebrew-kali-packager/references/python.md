# Python formulae

Use this for any Python CLI tool. Examples in homebrew-core: `sqlmap`, `theharvester`, `dnsrecon`, `wfuzz`, `impacket-scripts`, `yt-dlp`. Read this carefully — Python is the trickiest ecosystem in Homebrew.

## The two patterns

There are two acceptable patterns for Python tools:

1. **`virtualenv_install_with_resources` pattern** — for tools published to PyPI with normal dependencies. This is the canonical pattern.
2. **`virtualenv_create` + manual** — for tools with weird build requirements or git-only sources.

Use pattern 1 unless you have a specific reason not to.

## Standard template (pattern 1)

```rbex
class Theharvester < Formula
  include Language::Python::Virtualenv

  desc "Gather emails, subdomains, hosts, employee names from public sources"
  homepage "https://github.com/laramies/theHarvester"
  url "https://files.pythonhosted.org/packages/source/t/theharvester/theHarvester-4.5.1.tar.gz"
  sha256 "REPLACE_WITH_REAL_SHA256"
  license "GPL-2.0-only"

  depends_on "rust" => :build  # only if a dep needs it (e.g. cryptography)
  depends_on "python@3.12"

  resource "aiodns" do
    url "https://files.pythonhosted.org/packages/source/a/aiodns/aiodns-3.2.0.tar.gz"
    sha256 "..."
  end

  # ... more resource blocks for every transitive dependency ...

  def install
    virtualenv_install_with_resources
  end

  test do
    output = shell_output("#{bin}/theHarvester --help")
    assert_match "theHarvester", output
  end
end
```

## Generating resource blocks

**Don't write these by hand.** Use Homebrew's tooling.

### If the package is on PyPI

1. Write the formula skeleton with `url`/`sha256`/`depends_on` but no `resource` blocks.
2. Save it to your tap's `Formula/` directory.
3. Run:
   ```bash
   brew update-python-resources <formula-name>
   ```
4. This auto-populates the `resource` blocks based on the package's published deps.

### If the package is git-only (no PyPI)

Use `homebrew-pypi-poet` manually:

```bash
# In a clean venv:
python3 -m venv /tmp/poet-env
source /tmp/poet-env/bin/activate
pip install homebrew-pypi-poet
pip install <the-tool-from-git>
poet <the-tool-name>
```

Paste the resulting blocks into the formula. Then test with `brew install --build-from-source`.

## Pinning to a git commit (no PyPI release)

Many Kali tools have no PyPI release. Pragmatic mode: pin to a commit SHA.

```rbex
class Bloodhound < Formula
  include Language::Python::Virtualenv

  desc "Active Directory attack path analysis"
  homepage "https://github.com/SpecterOps/BloodHound.py"
  url "https://github.com/SpecterOps/BloodHound.py.git",
      tag:      "v1.7.2",
      revision: "REPLACE_WITH_COMMIT_SHA"
  license "MIT"
  version "1.7.2"

  # ... resources, install, test ...
end
```

For projects without tags but with stable `main`/`master`:

```rbex
url "https://github.com/example/tool.git",
    revision: "abc123def456..."
version "0.1.0-20260101"  # YYYYMMDD of the commit
```

Document this in a comment at the top of the formula:
```rbex
# Upstream has no releases; pinning to a commit on master.
# Bump revision on a regular cadence and update version accordingly.
```

## Common Python deps that need extra setup

| Python dep | Extra `depends_on` |
|---|---|
| `cryptography` (any version) | `"rust" => :build`, `"openssl@3"` |
| `pillow` | `"jpeg-turbo"`, `"libtiff"`, `"little-cms2"`, `"openjpeg"`, `"webp"` |
| `lxml` | `"libxml2"`, `"libxslt"` |
| `psycopg2` | `"libpq"` |
| `mysqlclient` | `"mysql-client"` or `"mysql"` |
| `psutil` | usually nothing |
| `pycurl` | `"curl"` |
| `gssapi` | `"krb5"` |

## Test patterns

Minimum:
```rbex
test do
  system bin/"<tool>", "--help"
end
```

Better — actually exercise the tool against safe input:
```rbex
test do
  output = shell_output("#{bin}/dnsrecon -d example.com -t std 2>&1", 0)
  assert_match "example.com", output
end
```

For tools that absolutely need a target/network, fall back to invalid input:
```rbex
test do
  # Should fail with helpful error, not crash
  output = shell_output("#{bin}/sqlmap -u 'http://invalid' --batch 2>&1", 1)
  assert_match "URL", output
end
```

## Choosing the Python version

- Use `depends_on "python@3.12"` (or whichever is current Homebrew default — check `brew info python`).
- Don't use `depends_on "python@3"` — pin to a specific minor.
- If upstream requires `<= 3.11`, pin accordingly and add a comment.

## Common pitfalls

- **Don't use `pip install`** in the install method. Use `virtualenv_install_with_resources`.
- **Don't bundle Python**. The formula depends on Homebrew's Python; users get a venv that uses it.
- **`include Language::Python::Virtualenv` must be at the top of the class.** Missing this is the #1 cause of "method not found" errors.
- **Resource versions matter for security tools.** Don't pin to old versions of `cryptography` or `requests` unless upstream requires it. Use the latest compatible version.
- **`brew update-python-resources` mutates the formula in place.** Commit before running it.

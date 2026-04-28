# Go formulae

Use this for any tool whose upstream is a Go module (look for `go.mod` in the repo root). Examples in homebrew-core: `gobuster`, `subfinder`, `naabu`, `nuclei`, `httpx`, `ffuf`, `amass`.

## Standard template

```ruby
class Gobuster < Formula
  desc "Directory/file, DNS and VHost busting tool written in Go"
  homepage "https://github.com/OJ/gobuster"
  url "https://github.com/OJ/gobuster/archive/refs/tags/v3.6.0.tar.gz"
  sha256 "REPLACE_WITH_REAL_SHA256"
  license "Apache-2.0"
  head "https://github.com/OJ/gobuster.git", branch: "master"

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    output = shell_output("#{bin}/gobuster --help")
    assert_match "gobuster", output
    assert_match "dir", output
  end
end
```

## Key points

- **`depends_on "go" => :build`** — Go is needed to build but not to run (binaries are static).
- **`std_go_args`** — Homebrew helper that expands to `-o #{bin}/<name> -trimpath`. Pass `ldflags: "-s -w"` to strip symbols and reduce binary size.
- **`head` block** — Optional but nice; lets users do `brew install --HEAD <name>`.
- **No runtime deps** — Go produces static binaries, so the formula usually has zero `depends_on` other than `go => :build`.

## Multi-binary Go projects

If the project produces multiple binaries (e.g. `cmd/foo` and `cmd/bar`):

```ruby
def install
  ldflags = "-s -w"
  system "go", "build", *std_go_args(ldflags: ldflags, output: bin/"foo"), "./cmd/foo"
  system "go", "build", *std_go_args(ldflags: ldflags, output: bin/"bar"), "./cmd/bar"
end
```

## Embedding version info

If upstream uses `-ldflags "-X main.version=..."` to inject the version (very common):

```ruby
def install
  ldflags = %W[
    -s -w
    -X main.Version=#{version}
    -X main.GitTag=v#{version}
  ]
  system "go", "build", *std_go_args(ldflags: ldflags)
end
```

Check upstream's `Makefile` or `goreleaser.yml` to find the exact ldflags they use.

## Shell completions

Many Go CLIs use cobra and ship completions via `<cmd> completion bash|zsh|fish`. Generate and install them:

```ruby
def install
  system "go", "build", *std_go_args(ldflags: "-s -w")
  generate_completions_from_executable(bin/"gobuster", "completion")
end
```

## Test patterns

Minimum acceptable:
```ruby
test do
  assert_match version.to_s, shell_output("#{bin}/gobuster version")
end
```

Better — exercise actual functionality with input that doesn't need network:
```ruby
test do
  # Should fail gracefully without a target
  output = shell_output("#{bin}/gobuster dir 2>&1", 1)
  assert_match "url", output.downcase
end
```

## Common pitfalls

- **CGO**: Some Go projects need CGO (e.g. for libpcap). Check `go.mod` for `cgo` build tags. If needed, add `depends_on "libpcap"` and ensure `CGO_ENABLED=1` (default).
- **Go workspace mode**: Newer projects may use `go.work`. `std_go_args` handles this fine, but the build path may differ — read upstream's build instructions.
- **Private modules**: Avoid. If upstream pulls private deps, you can't build it cleanly.
- **GOPROXY**: Don't set it in formulae. Homebrew's build env handles this.

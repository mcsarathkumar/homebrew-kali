class Seclists < Formula
  desc "Collection of multiple types of lists used during security assessments"
  homepage "https://github.com/danielmiessler/SecLists"
  url "https://github.com/danielmiessler/SecLists/archive/refs/tags/2026.1.tar.gz"
  sha256 "226c49d04974ec6c39dadbf38ba78e67fec8824d729e66907f6050329da98932"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  def install
    # SecLists is a data-only package: a large collection of wordlists.
    # Install everything into pkgshare so users can reference paths via
    # `$(brew --prefix)/share/seclists/...`.
    rm_r ".github" if File.directory?(".github")

    pkgshare.install Dir["*"]
  end

  def caveats
    <<~EOS
      SecLists wordlists are installed to:
        #{opt_pkgshare}

      Common usage with other tools:
        ffuf -w #{opt_pkgshare}/Discovery/Web-Content/common.txt -u https://example.com/FUZZ
        gobuster dir -w #{opt_pkgshare}/Discovery/Web-Content/directory-list-2.3-medium.txt -u https://example.com
    EOS
  end

  test do
    # A handful of well-known wordlists must be present after install.
    assert_path_exists pkgshare/"Discovery/Web-Content/common.txt"
    assert_path_exists pkgshare/"Passwords/Common-Credentials/xato-net-10-million-passwords-1000.txt"
    assert_path_exists pkgshare/"Usernames/top-usernames-shortlist.txt"

    # Sanity-check that common.txt has plausible content.
    assert_match(/admin/i, (pkgshare/"Discovery/Web-Content/common.txt").read)
  end
end

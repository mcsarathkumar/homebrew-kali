#!/usr/bin/env bash
# dev-setup.sh — register this working tree as a local Homebrew tap so
# you can `brew install mcsarathkumar/kali/<formula>` against your branch
# without pushing first.
#
# Idempotent. Safe to re-run.
#
# Usage:
#   ./scripts/dev-setup.sh

set -euo pipefail

TAP_USER="mcsarathkumar"
TAP_NAME="kali"
TAP_DIR_NAME="homebrew-${TAP_NAME}"

# Resolve absolute path of this repo (the directory above the scripts/ dir).
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v brew >/dev/null 2>&1; then
  echo "error: brew not found on PATH. Install Homebrew first: https://brew.sh" >&2
  exit 1
fi

TAPS_PARENT="$(brew --repository)/Library/Taps/${TAP_USER}"
TAP_LINK="${TAPS_PARENT}/${TAP_DIR_NAME}"

mkdir -p "${TAPS_PARENT}"

# If something already exists at TAP_LINK and it's not pointing at our repo,
# warn rather than clobber it.
if [[ -e "${TAP_LINK}" && ! -L "${TAP_LINK}" ]]; then
  echo "error: ${TAP_LINK} already exists and is not a symlink." >&2
  echo "       Move it aside (e.g. brew untap ${TAP_USER}/${TAP_NAME}) and retry." >&2
  exit 1
fi

ln -sfn "${REPO_ROOT}" "${TAP_LINK}"
echo "linked ${TAP_LINK} -> ${REPO_ROOT}"

echo
echo "Registered taps:"
brew tap | sed 's/^/  /'

echo
echo "Try it out:"
echo "  brew install --build-from-source ${TAP_USER}/${TAP_NAME}/seclists"
echo "  brew test                          ${TAP_USER}/${TAP_NAME}/seclists"
echo "  brew audit --strict --new          ${TAP_USER}/${TAP_NAME}/seclists"
echo "  brew style --fix                   ${TAP_USER}/${TAP_NAME}/seclists"

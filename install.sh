#!/bin/sh
# Anymatix installer — macOS and Linux.
#
#   curl -fsSL https://raw.githubusercontent.com/Anymatix/anymatix-beta/main/install.sh | sh
#
# What it does: asks GitHub for the LATEST Anymatix release, picks the asset
# that matches this operating system and processor, downloads it into a
# directory of its own, clears the quarantine flag macOS puts on anything
# downloaded, and opens it. It installs nothing by itself — on macOS the disk
# image opens and you drag Anymatix to Applications, which is the same gesture
# as any other Mac app.
#
# No version is written down anywhere in this file. The release it fetches is
# whatever /releases/latest returns on the day you run it.
#
# It never asks for a password, never runs sudo, and writes only inside the
# download directory it creates.
#
# Before it downloads anything it asks you to accept the Beta Tester Voluntary
# Contributor Agreement (the terms of the beta), and prints the URL where the
# same text lives online. Press Enter to accept, or type cancel to refuse — a
# refusal exits without downloading anything. For unattended runs (CI, a
# provisioning script) where nobody is at the prompt to answer, set
# ANYMATIX_ACCEPT_TERMS=1 to accept the agreement non-interactively; with no
# terminal to ask on, the script otherwise refuses by default rather than
# guessing.
#
# Maintained in the anymatix superproject and published from there to
# github.com/Anymatix/anymatix-beta. Edit it there, not here.

set -eu

REPO="Anymatix/anymatix-beta"
API="https://api.github.com/repos/${REPO}/releases/latest"
AGREEMENT_URL="https://anymatix-2925e.web.app/beta-agreement"

say()  { printf '%s\n' "$*"; }
step() { printf '\n==> %s\n' "$*"; }
die()  { printf '\nAnymatix installer: %s\n' "$*" >&2; exit 1; }

need() {
  command -v "$1" >/dev/null 2>&1 || die "this needs \`$1\`, which is not installed. Install $1 and run the command again."
}

# ------------------------------------------------------------------- terms ---

terms_gate() {
  if [ "${ANYMATIX_ACCEPT_TERMS:-}" = "1" ]; then
    step "Beta Tester Voluntary Contributor Agreement"
    say "    the terms: ${AGREEMENT_URL}"
    say "    accepted automatically (ANYMATIX_ACCEPT_TERMS=1)."
    return 0
  fi

  step "Beta Tester Voluntary Contributor Agreement"
  say "    read the terms: ${AGREEMENT_URL}"
  say ""
  say "    ============================================================"
  say "    PRESS ENTER IF YOU ACCEPT THE TERMS, OR TYPE cancel TO REFUSE"
  say "    ============================================================"

  if ! { exec 3</dev/tty; } 2>/dev/null; then
    die "no terminal to ask for consent on (this looks like a non-interactive run, e.g. CI) — refusing by default. Terms refused. Nothing was downloaded. To automate this, accept the agreement above and re-run with ANYMATIX_ACCEPT_TERMS=1."
  fi

  trap 'printf "\nAnymatix installer: Terms refused. Nothing was downloaded.\n" >&2; exit 1' INT

  while true; do
    printf '> ' > /dev/tty
    if ! IFS= read -r REPLY <&3; then
      printf "\nAnymatix installer: Terms refused. Nothing was downloaded.\n" >&2
      exit 1
    fi
    case "$REPLY" in
      "") break ;;
      [Cc][Aa][Nn][Cc][Ee][Ll]) printf "\nAnymatix installer: Terms refused. Nothing was downloaded.\n" >&2; exit 1 ;;
      *) say "    please press Enter to accept, or type cancel to refuse." ;;
    esac
  done

  trap - INT
  exec 3<&-
}

terms_gate

# ---------------------------------------------------------------- platform ---

OS="$(uname -s)"
ARCH="$(uname -m)"

step "Looking at this machine"
say "    system:    ${OS}"
say "    processor: ${ARCH}"

# The asset patterns below are matched against the release's asset names. They
# are deliberately written as patterns and not as filenames, so that the day a
# Linux artifact is published the script finds it WITHOUT AN EDIT: the Linux
# branch already asks for *.AppImage and simply reports that none is there yet.
case "$OS" in
  Darwin)
    PLATFORM="macOS"
    case "$ARCH" in
      arm64|aarch64) ASSET_PATTERN='\.dmg$' ;;
      x86_64)        ASSET_PATTERN='\.dmg$' ;;
      *)             die "Anymatix has no macOS build for a ${ARCH} processor. Apple silicon (arm64) is what the beta ships." ;;
    esac
    ;;
  Linux)
    PLATFORM="Linux"
    case "$ARCH" in
      x86_64|amd64)  ASSET_PATTERN='x86_64\.AppImage$|amd64\.AppImage$|\.AppImage$' ;;
      aarch64|arm64) ASSET_PATTERN='aarch64\.AppImage$|arm64\.AppImage$' ;;
      *)             die "Anymatix has no Linux build for a ${ARCH} processor." ;;
    esac
    ;;
  *)
    die "this script covers macOS and Linux. On Windows, open PowerShell and run: irm https://raw.githubusercontent.com/${REPO}/main/install.ps1 | iex"
    ;;
esac

need curl

# ------------------------------------------------------------------ release ---

step "Asking GitHub for the latest Anymatix release"

RELEASE_JSON="$(curl -fsSL -H 'Accept: application/vnd.github+json' "$API")" \
  || die "could not reach the GitHub releases API. Check the network and try again."

[ -n "$RELEASE_JSON" ] || die "GitHub returned nothing for the latest release."

# One awk pass over the JSON, no jq dependency: collect the tag and the
# browser_download_url of every asset whose name matches this platform.
TAG="$(printf '%s' "$RELEASE_JSON" \
  | tr ',' '\n' \
  | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
  | head -n 1)"

[ -n "$TAG" ] || die "the latest release has no tag name — nothing to install."

say "    latest release: ${TAG}"

URL="$(printf '%s' "$RELEASE_JSON" \
  | tr ',' '\n' \
  | sed -n 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
  | grep -E "$ASSET_PATTERN" \
  | head -n 1)"

if [ -z "$URL" ]; then
  if [ "$PLATFORM" = "Linux" ]; then
    # Deliberate, and the honest state of the project as of this writing: the
    # build workflow has a Linux job but no release carries an .AppImage yet.
    # Exit non-zero rather than 404 into a shell. When the first AppImage is
    # published this branch stops being reached and nothing here changes.
    die "Anymatix has no Linux build yet — release ${TAG} publishes macOS and Windows only. Linux is coming; watch https://github.com/${REPO}/releases."
  fi
  die "release ${TAG} has no asset for ${PLATFORM} on ${ARCH}. Pick a file by hand at https://github.com/${REPO}/releases/latest"
fi

FILENAME="$(basename "$URL")"
say "    asset:          ${FILENAME}"

# ----------------------------------------------------------------- download ---

DOWNLOAD_DIR="${HOME}/Downloads"
[ -d "$DOWNLOAD_DIR" ] || DOWNLOAD_DIR="$(pwd)"
TARGET_DIR="${DOWNLOAD_DIR}/anymatix-${TAG}"
TARGET="${TARGET_DIR}/${FILENAME}"

step "Downloading into ${TARGET_DIR}"
say "    this is a large file — half a gigabyte or so. It will take a while."

mkdir -p "$TARGET_DIR"

# -C - resumes a download interrupted earlier. --fail makes a 404 an error
# instead of a saved HTML page.
curl -fL --progress-bar -C - -o "$TARGET" "$URL" \
  || die "the download did not complete. Run the same command again — it resumes from where it stopped."

[ -s "$TARGET" ] || die "the downloaded file is empty. Delete ${TARGET} and run the command again."

# A truncated download is the failure this catches: curl exits 0 on a connection
# that closed cleanly mid-file, so compare against the size GitHub advertised.
EXPECTED_SIZE="$(printf '%s' "$RELEASE_JSON" \
  | tr ',' '\n' \
  | awk -v want="\"${FILENAME}\"" '
      index($0, want)                 { seen = 1 }
      seen && /"size"[[:space:]]*:/   { gsub(/[^0-9]/, ""); if (length($0)) { print; exit } }
    ')"

if [ -n "${EXPECTED_SIZE:-}" ]; then
  ACTUAL_SIZE="$(wc -c < "$TARGET" | tr -d ' ')"
  if [ "$ACTUAL_SIZE" != "$EXPECTED_SIZE" ]; then
    die "the download is incomplete: ${ACTUAL_SIZE} bytes of ${EXPECTED_SIZE}. Run the same command again to resume."
  fi
  say "    downloaded ${ACTUAL_SIZE} bytes, which is the whole file."
fi

# ------------------------------------------------------------------- unlock ---

if [ "$PLATFORM" = "macOS" ]; then
  step "Clearing the quarantine flag macOS puts on downloaded files"
  say "    Anymatix beta builds are unsigned, so without this macOS refuses to open the disk image."
  xattr -d com.apple.quarantine "$TARGET" 2>/dev/null || true
  xattr -c "$TARGET" 2>/dev/null || true

  step "Opening the disk image"
  say "    drag Anymatix into Applications in the window that appears."
  open "$TARGET" || die "could not open ${TARGET}. Open it from Finder instead."

  step "Done"
  say "    the disk image is at ${TARGET}"
  say "    after dragging Anymatix to Applications you can eject it and delete the file."
else
  step "Making the AppImage executable"
  chmod +x "$TARGET"

  step "Done"
  say "    run it with: ${TARGET}"
fi

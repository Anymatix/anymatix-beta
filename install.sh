#!/bin/sh
# Anymatix installer — macOS and Linux.
#
#   curl -fsSL https://raw.githubusercontent.com/Anymatix/anymatix-beta/main/install.sh | sh
#
# What it does: asks GitHub for the LATEST Anymatix release, picks the asset
# that matches this operating system and processor, downloads it into a
# directory of its own, VERIFIES ITS SHA-256 against the SHA256SUMS.txt the
# release publishes and then, on macOS, INSTALLS IT ITSELF: it mounts the disk
# image, copies Anymatix into /Applications with `ditto`, clears the quarantine
# flag macOS puts on anything downloaded, ejects the image, and starts the app.
# Nobody drags anything. On Linux it marks the AppImage executable and tells you
# where it is, because there is nothing to install.
#
# The checksum is not a nicety, it is the only check that can be trusted. The
# download resumes an interrupted attempt, and on 2026-09-20 a part-file left
# by a DIFFERENT build of the same version was resumed to exactly the right
# total size: the size check passed, the disk image was corrupt, and hdiutil
# refused it with a CRC error. Size says how much arrived; only the hash says
# WHAT arrived. So: a file whose hash does not match the published one is
# deleted and fetched once more from scratch, and if the release publishes no
# SHA256SUMS.txt — or no line for this file — the script refuses rather than
# hand over something it cannot verify. The same hash is what lets a re-run be
# cheap: a disk image already on disk whose sha256 IS the published one is not
# downloaded a second time.
#
# A verified download is not a working app. Also on 2026-09-20 a build was
# published whose app.asar had every dependency packed one level too deep
# (`/node_modules/node_modules/…`, with `/node_modules/` empty), so the app
# died at launch with *Cannot find module 'fs-extra'*. The checksum was
# perfect: it was the right bytes of a broken package. So after the copy, and
# BEFORE anything replaces an Anymatix you already have, the installer reads
# the copy's asar header and requires `/node_modules/fs-extra/package.json` to
# be there at the top level. If it is not, the copy is deleted, whatever was
# already installed is left exactly as it was, and the script refuses.
#
# The copy is staged under a temporary name inside /Applications and only
# renamed into place once that check has passed. A failed install therefore
# cannot leave you worse off than before you ran it.
#
# No version is written down anywhere in this file. The release it fetches is
# whatever /releases/latest returns on the day you run it.
#
# It never asks for a password and NEVER RUNS sudo. If /Applications is not
# writable by your account it says so and stops, rather than escalating.
# It writes only inside the download directory it creates and /Applications.
#
# If an Anymatix is already in /Applications and RUNNING, it will not be
# replaced underneath itself: the script says so and waits for you to quit it.
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
# Options (pass them after `| sh -s --`, e.g.
#   curl -fsSL …/install.sh | sh -s -- --no-launch)
#
#   --no-launch          install, but do not start the app afterwards.
#   --no-install         the old behaviour: download, verify, and just open the
#                        disk image so you can drag Anymatix in yourself.
#   --delete-download    delete the downloaded disk image once the install has
#                        succeeded. By default it is KEPT, and the script says
#                        where, so a reinstall costs nothing.
#   --appimage <file>    Linux: install an AppImage you already have, the same
#                        way (--dmg's rules apply: no checksum gate on it).
#   --dmg <file>         install a disk image you already have instead of
#                        downloading one. The download's checksum gate belongs
#                        to the download: a file you pointed at yourself is
#                        taken as chosen, its sha256 is printed for the record,
#                        and the packaging check above still applies.
#   -h, --help           print this list and exit.
#
# Maintained in the anymatix superproject and published from there to
# github.com/Anymatix/anymatix-beta. Edit it there, not here.

set -eu

REPO="Anymatix/anymatix-beta"
# The branch the Linux FUSE 2 library is fetched from. `main` for everyone;
# settable only so a change to this script can be tried before it is merged.
REF="${ANYMATIX_INSTALLER_REF:-main}"
API="https://api.github.com/repos/${REPO}/releases/latest"
AGREEMENT_URL="https://anymatix-2925e.web.app/beta-agreement"

say()  { printf '%s\n' "$*"; }
step() { printf '\n==> %s\n' "$*"; }
die()  { printf '\nAnymatix installer: %s\n' "$*" >&2; exit 1; }

need() {
  command -v "$1" >/dev/null 2>&1 || die "this needs \`$1\`, which is not installed. Install $1 and run the command again."
}

# Written out rather than scraped from the comment above, because the usual way
# to run this script is `curl … | sh`, where there is no file on disk to read.
usage() {
  say "Anymatix installer. Run it with no options to download the latest beta,"
  say "install it into /Applications and start it."
  say ""
  say "  --no-launch          install, but do not start the app afterwards"
  say "  --no-install         download and verify only, then open the disk image"
  say "                       so you can drag Anymatix in yourself"
  say "  --delete-download    delete the disk image after a successful install"
  say "                       (by default it is kept, and the path is printed)"
  say "  --appimage <file>    Linux: install an AppImage you already have"
  say "  --dmg <file>         install a disk image you already have, instead of"
  say "                       downloading one"
  say "  -h, --help           this list"
  say ""
  say "Piped into sh, options go after -s --, like this:"
  say "  curl -fsSL https://raw.githubusercontent.com/${REPO}/main/install.sh | sh -s -- --no-launch"
}

# ------------------------------------------------------------------ options ---

DO_INSTALL=1
DO_LAUNCH=1
DELETE_DOWNLOAD=0
LOCAL_IMAGE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --no-launch)       DO_LAUNCH=0 ;;
    --no-install)      DO_INSTALL=0 ;;
    --delete-download) DELETE_DOWNLOAD=1 ;;
    --dmg)
      [ $# -ge 2 ] || die "--dmg needs the path of a disk image."
      LOCAL_IMAGE="$2"
      shift
      ;;
    --dmg=*)           LOCAL_IMAGE="${1#--dmg=}" ;;
    --appimage)
      [ $# -ge 2 ] || die "--appimage needs the path of an AppImage."
      LOCAL_IMAGE="$2"
      shift
      ;;
    --appimage=*)      LOCAL_IMAGE="${1#--appimage=}" ;;
    -h|--help)         usage; exit 0 ;;
    *)                 die "unknown option \`$1\`. Run with --help for the list." ;;
  esac
  shift
done

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
    case "$LOCAL_IMAGE" in
      ''|*.AppImage) ;;
      *) die "on Linux, point --appimage at an .AppImage file (--dmg is a macOS disk image)." ;;
    esac
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

# --------------------------------------------------------------- checksums ---

if command -v shasum >/dev/null 2>&1; then
  sha256_of() { shasum -a 256 "$1" | cut -d' ' -f1; }
elif command -v sha256sum >/dev/null 2>&1; then
  sha256_of() { sha256sum "$1" | cut -d' ' -f1; }
else
  die "this needs \`shasum\` or \`sha256sum\` to verify the download, and neither is installed. Install one of them and run the command again."
fi

# ------------------------------------------------- the asar packaging check ---

# Reads the app.asar header — the JSON directory at the front of the archive —
# and answers ONE question: is there a `/node_modules/fs-extra/package.json`
# entry at the TOP level? `fs-extra` is required by `electron-updater` in the
# main process, so an app.asar without it at the top level cannot start; that
# is exactly the shape of the build that shipped broken on 2026-09-20, where
# the whole tree had been packed under `/node_modules/node_modules/`.
#
# The format: four little-endian uint32 at the front, the fourth (at offset 12)
# being the length of the JSON header, which starts at offset 16.
#
# The scan is a brace-depth walk, not a grep: `"fs-extra"` appearing SOMEWHERE
# in the header proves nothing at all — in the broken build it appeared too,
# one level down. awk splits the record on `{` so that the per-character work
# happens on short pieces (a whole-header character walk is a hundred times
# slower); a `{` that falls inside a quoted string is put back rather than
# counted, which is what keeps the depth honest.
asar_has_top_level_fs_extra() {
  _asar="$1"
  [ -f "$_asar" ] || return 3

  _hdrlen="$(od -An -tu4 -j12 -N4 "$_asar" 2>/dev/null | tr -d ' \n')"
  case "$_hdrlen" in
    ''|*[!0-9]*) return 3 ;;
  esac
  [ "$_hdrlen" -gt 2 ] || return 3
  [ "$_hdrlen" -lt 67108864 ] || return 3

  tail -c "+17" "$_asar" | head -c "$_hdrlen" | awk '
    BEGIN { RS = "{"; depth = 0; instr = 0; pend = ""; cur = ""; laststr = ""; found = 0 }
    {
      rec = $0; n = length(rec); i = 1
      while (i <= n) {
        c = substr(rec, i, 1)
        if (instr) {
          if (c == "\\") { i += 2; continue }
          if (c == "\"") { instr = 0; laststr = cur; i++; continue }
          cur = cur c; i++; continue
        }
        if (c == "\"") { instr = 1; cur = ""; i++; continue }
        if (c == ":")  { pend = laststr; i++; continue }
        if (c == "}")  { depth--; i++; continue }
        i++
      }
      if (instr) { cur = cur "{"; next }
      depth++
      key[depth] = pend
      pend = ""
      if (depth == 7 && key[2] == "files" && key[3] == "node_modules" && key[4] == "files" && key[5] == "fs-extra" && key[6] == "files" && key[7] == "package.json") { found = 1; exit }
    }
    END { exit (found ? 0 : 3) }
  '
}

# ------------------------------------------------------------------ release ---

if [ -n "$LOCAL_IMAGE" ]; then
  [ -f "$LOCAL_IMAGE" ] || die "there is no file at ${LOCAL_IMAGE}."
  TARGET="$LOCAL_IMAGE"
  TAG="(the image you pointed at)"
  step "Using the disk image you already have"
  say "    image:  ${TARGET}"
  say "    sha256: $(sha256_of "$TARGET")"
  say "    you chose this file, so it is not checked against a published"
  say "    checksum — that gate belongs to the download this run skipped."
else
  need curl

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

  # --------------------------------------------------------------- checksum ---

  # Resolved BEFORE the download: refusing after half a gigabyte has arrived
  # would be rude, and there is nothing this script can do with an unverifiable
  # asset except refuse it.
  SUMS_URL="$(printf '%s' "$RELEASE_JSON" \
    | tr ',' '\n' \
    | sed -n 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | grep -E '/SHA256SUMS\.txt$' \
    | head -n 1)"

  step "Asking GitHub for the published checksums"

  [ -n "$SUMS_URL" ] || die "release ${TAG} publishes no SHA256SUMS.txt, so there is nothing to verify ${FILENAME} against. Refusing to install an unverified download. Report this — a release without checksums is a mistake in the release, not on your machine."

  SUMS="$(curl -fsSL "$SUMS_URL")" \
    || die "could not fetch the published checksums from ${SUMS_URL}. Refusing to install an unverified download. Check the network and run the command again."

  EXPECTED_SHA="$(printf '%s\n' "$SUMS" \
    | awk -v want="$FILENAME" '{ name = $NF; sub(/^\*/, "", name); if (name == want) { print $1; exit } }')"

  [ -n "$EXPECTED_SHA" ] || die "SHA256SUMS.txt for release ${TAG} has no line for ${FILENAME}, so this download cannot be verified. Refusing to install an unverified download. Report this — the release is incomplete."

  say "    published sha256: ${EXPECTED_SHA}"

  # --------------------------------------------------------------- download ---

  DOWNLOAD_DIR="${HOME}/Downloads"
  [ -d "$DOWNLOAD_DIR" ] || DOWNLOAD_DIR="$(pwd)"
  TARGET_DIR="${DOWNLOAD_DIR}/anymatix-${TAG}"
  TARGET="${TARGET_DIR}/${FILENAME}"

  mkdir -p "$TARGET_DIR"

  # A file already on disk whose hash IS the published one is the release, and
  # fetching half a gigabyte again to learn that would be silly. Anything else
  # — a short file, a part-file, a different build — falls through to the
  # resuming download below, which is what it is for. Nothing is deleted here:
  # a partial download is worth resuming.
  SKIP_DOWNLOAD=0
  if [ -s "$TARGET" ] && [ "$(sha256_of "$TARGET")" = "$EXPECTED_SHA" ]; then
    step "The disk image is already here"
    say "    ${TARGET}"
    say "    its sha256 is the published one, so it is not downloaded again."
    SKIP_DOWNLOAD=1
  fi

  if [ "$SKIP_DOWNLOAD" = 0 ]; then

  step "Downloading into ${TARGET_DIR}"
  say "    this is a large file — half a gigabyte or so. It will take a while."

  # The size GitHub advertised. It is the cheap first signal — it catches a
  # truncated download (curl exits 0 on a connection that closed cleanly
  # mid-file) without hashing half a gigabyte — but it is never the last word.
  EXPECTED_SIZE="$(printf '%s' "$RELEASE_JSON" \
    | tr ',' '\n' \
    | awk -v want="\"${FILENAME}\"" '
        index($0, want)                 { seen = 1 }
        seen && /"size"[[:space:]]*:/   { gsub(/[^0-9]/, ""); if (length($0)) { print; exit } }
      ')"

  # Two attempts at most: the first may resume whatever is already on disk, the
  # second always starts from nothing. A file that fails the checksum twice is
  # not a download problem, and saying so is more use than resuming forever.
  ATTEMPT=1
  while : ; do
    if [ "$ATTEMPT" = 1 ]; then
      # -C - resumes a download interrupted earlier. --fail makes a 404 an error
      # instead of a saved HTML page.
      curl -fL --progress-bar -C - -o "$TARGET" "$URL" \
        || die "the download did not complete. Run the same command again — it resumes from where it stopped."
    else
      rm -f "$TARGET"
      curl -fL --progress-bar -o "$TARGET" "$URL" \
        || die "the second download did not complete either. Delete ${TARGET} and run the same command again."
    fi

    PROBLEM=""
    if [ ! -s "$TARGET" ]; then
      PROBLEM="the downloaded file is empty"
    else
      ACTUAL_SIZE="$(wc -c < "$TARGET" | tr -d ' ')"
      if [ -n "${EXPECTED_SIZE:-}" ] && [ "$ACTUAL_SIZE" != "$EXPECTED_SIZE" ]; then
        PROBLEM="the file is ${ACTUAL_SIZE} bytes where release ${TAG} says ${EXPECTED_SIZE}"
      else
        if [ -n "${EXPECTED_SIZE:-}" ]; then
          say "    downloaded ${ACTUAL_SIZE} bytes, which is the whole file."
        fi

        step "Verifying the download against the published checksum"
        ACTUAL_SHA="$(sha256_of "$TARGET")"
        if [ "$ACTUAL_SHA" = "$EXPECTED_SHA" ]; then
          say "    checksum verified: sha256 ${ACTUAL_SHA} matches the published SHA256SUMS.txt."
          break
        fi
        PROBLEM="this file does NOT match the published checksum — its sha256 is ${ACTUAL_SHA}, and release ${TAG} publishes ${EXPECTED_SHA}"
      fi
    fi

    if [ "$ATTEMPT" = 1 ]; then
      say ""
      say "    ${PROBLEM}."
      say "    A resumed download can reach exactly the right size and still be the"
      say "    wrong bytes — a part-file left by another build of the same version is"
      say "    all it takes. Deleting it and downloading once more from scratch."
      ATTEMPT=2
      continue
    fi

    die "${PROBLEM} — and that was a fresh download, not a resumed one. Nothing was installed. Delete ${TARGET} and try again; if it happens twice more, something between you and GitHub is altering the file (a proxy or a captive portal will do this), so download it by hand from https://github.com/${REPO}/releases/latest and check its sha256 against SHA256SUMS.txt yourself."
  done

  fi
fi

# ------------------------------------------------------------------- Linux ---

# THE APPIMAGE GOES TO A PATH WITH NO VERSION IN IT. The app updates itself by
# replacing the file it was started from; a name carrying the version makes
# the updater write a NEW file and delete the old one, which would strand the
# launcher below on a path that no longer exists.
#
# FUSE 2. AppImages mount themselves with libfuse.so.2, which Ubuntu 22.04 and
# later no longer install ("dlopen(): error loading libfuse.so.2" and the app
# never opens — measured on Ubuntu 26.04, 2026-09-25). In order:
#   1. the system has libfuse.so.2        -> nothing extra;
#   2. it does not                         -> our copy (lib/, checksummed here),
#      handed to this app alone through the launcher's LD_LIBRARY_PATH — no
#      root, nothing system-wide, and updates keep working;
#   3. even that cannot mount the image    -> unpack it and run it unpacked,
#      and say plainly that it will then NOT update itself.
if [ "$PLATFORM" != "macOS" ]; then
  LINUX_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/anymatix"
  APPIMAGE_DEST="${LINUX_HOME}/Anymatix.AppImage"
  LAUNCHER_DIR="${HOME}/.local/bin"
  LAUNCHER="${LAUNCHER_DIR}/anymatix"
  mkdir -p "$LINUX_HOME" "$LAUNCHER_DIR" || die "could not create ${LINUX_HOME}."

  step "Installing the AppImage"
  cp "$TARGET" "${APPIMAGE_DEST}.new" && chmod +x "${APPIMAGE_DEST}.new" \
    && mv -f "${APPIMAGE_DEST}.new" "$APPIMAGE_DEST" \
    || die "could not copy the AppImage to ${APPIMAGE_DEST}. The download is still at ${TARGET}."
  say "    ${APPIMAGE_DEST}"

  # Does it mount? `--appimage-mount` mounts and prints the mount point, then
  # waits; a line that is a directory is a yes. Run in the background and
  # stopped either way.
  appimage_mounts() {
    _out="$(mktemp)"
    env LD_LIBRARY_PATH="$1" "$APPIMAGE_DEST" --appimage-mount >"$_out" 2>/dev/null &
    _pid=$!
    _i=0; _ok=1
    while [ "$_i" -lt 20 ]; do
      _mp="$(head -n 1 "$_out" 2>/dev/null)"
      if [ -n "$_mp" ] && [ -d "$_mp" ]; then _ok=0; break; fi
      kill -0 "$_pid" 2>/dev/null || break
      sleep 0.5; _i=$((_i + 1))
    done
    kill "$_pid" 2>/dev/null; wait "$_pid" 2>/dev/null
    rm -f "$_out"
    return "$_ok"
  }

  have_system_fuse2() {
    ldconfig -p 2>/dev/null | grep -q 'libfuse\.so\.2 ' && return 0
    for _d in /lib /usr/lib /lib64 /usr/lib64 /lib/*-linux-gnu /usr/lib/*-linux-gnu; do
      [ -e "${_d}/libfuse.so.2" ] && return 0
    done
    return 1
  }

  FUSE_LIB_DIR=""
  RUN_MODE="appimage"
  step "Checking FUSE 2, which AppImages need"
  if have_system_fuse2; then
    say "    this system has libfuse.so.2."
  else
    case "$ARCH" in
      x86_64|amd64)  _LIB_ARCH="linux-x86_64";  _LIB_SHA="0c2b629ecbb29c36a8089e15fa69216869494850a7d00710ebe7707dc1b3b828" ;;
      aarch64|arm64) _LIB_ARCH="linux-aarch64"; _LIB_SHA="01734bd23c8f6f3b5ac7a662c7a5cf6156cdfd1239c0c1cbf44c30cb6d7a3200" ;;
    esac
    say "    this system has no libfuse.so.2 (Ubuntu 22.04 and later do not install it)."
    say "    using the copy Anymatix ships, for Anymatix only — no root, nothing system-wide."
    FUSE_LIB_DIR="${LINUX_HOME}/lib"
    mkdir -p "$FUSE_LIB_DIR"
    if curl -fsSL "https://raw.githubusercontent.com/${REPO}/${REF}/lib/${_LIB_ARCH}/libfuse.so.2" -o "${FUSE_LIB_DIR}/libfuse.so.2.part" \
      && [ "$(sha256_of "${FUSE_LIB_DIR}/libfuse.so.2.part")" = "$_LIB_SHA" ]; then
      mv -f "${FUSE_LIB_DIR}/libfuse.so.2.part" "${FUSE_LIB_DIR}/libfuse.so.2"
    else
      rm -f "${FUSE_LIB_DIR}/libfuse.so.2.part"
      say "    could not fetch it, or its checksum did not match."
      FUSE_LIB_DIR=""
      RUN_MODE="extract"
    fi
  fi

  if [ "$RUN_MODE" = "appimage" ] && ! appimage_mounts "$FUSE_LIB_DIR"; then
    say "    the AppImage still cannot mount itself here."
    RUN_MODE="extract"
  fi

  if [ "$RUN_MODE" = "extract" ]; then
    step "Unpacking the AppImage instead (no FUSE needed)"
    say "    NOTE: an unpacked Anymatix does NOT update itself. To update, run this"
    say "    installer again; or install libfuse2 (e.g. sudo apt install libfuse2t64)"
    say "    and re-run it to get self-updates back."
    rm -rf "${LINUX_HOME}/app" "${LINUX_HOME}/squashfs-root"
    ( cd "$LINUX_HOME" && "$APPIMAGE_DEST" --appimage-extract >/dev/null 2>&1 ) \
      && mv "${LINUX_HOME}/squashfs-root" "${LINUX_HOME}/app" \
      || die "could not unpack ${APPIMAGE_DEST}. Install libfuse2 (sudo apt install libfuse2t64 on Ubuntu) and run this installer again."
  fi

  step "Writing the launcher"
  if [ "$RUN_MODE" = "extract" ]; then
    printf '#!/bin/sh\n# Written by the Anymatix installer. Unpacked mode: no self-update.\nAPPDIR="%s" exec "%s/AppRun" "$@"\n' \
      "${LINUX_HOME}/app" "${LINUX_HOME}/app" > "$LAUNCHER"
  elif [ -n "$FUSE_LIB_DIR" ]; then
    printf '#!/bin/sh\n# Written by the Anymatix installer: FUSE 2 for this app only.\nLD_LIBRARY_PATH="%s${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" exec "%s" "$@"\n' \
      "$FUSE_LIB_DIR" "$APPIMAGE_DEST" > "$LAUNCHER"
  else
    printf '#!/bin/sh\n# Written by the Anymatix installer.\nexec "%s" "$@"\n' "$APPIMAGE_DEST" > "$LAUNCHER"
  fi
  chmod +x "$LAUNCHER"
  say "    ${LAUNCHER}"

  APPS_ENTRY_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/applications"
  mkdir -p "$APPS_ENTRY_DIR" && printf '[Desktop Entry]\nType=Application\nName=Anymatix\nExec=%s %%U\nTerminal=false\nCategories=Graphics;\n' "$LAUNCHER" \
    > "${APPS_ENTRY_DIR}/anymatix.desktop" && say "    menu entry: ${APPS_ENTRY_DIR}/anymatix.desktop"

  step "Done"
  case ":${PATH}:" in
    *":${LAUNCHER_DIR}:"*) say "    start it with: anymatix   (or from your applications menu)" ;;
    *)                     say "    start it with: ${LAUNCHER}   (or from your applications menu)" ;;
  esac
  if [ "$DO_LAUNCH" = 1 ] && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
    nohup "$LAUNCHER" >/dev/null 2>&1 &
    say "    started."
  fi
  exit 0
fi

# ------------------------------------------------------------------- unlock ---

step "Clearing the quarantine flag macOS puts on downloaded files"
say "    Anymatix beta builds are unsigned, so without this macOS refuses to open the disk image."
xattr -d com.apple.quarantine "$TARGET" 2>/dev/null || true
xattr -c "$TARGET" 2>/dev/null || true

# ----------------------------------------------------- download-only branch ---

if [ "$DO_INSTALL" = 0 ]; then
  step "Opening the disk image (--no-install: you install it yourself)"
  say "    drag Anymatix into Applications in the window that appears."
  open "$TARGET" || die "could not open ${TARGET}. Open it from Finder instead."

  step "Done"
  say "    the disk image is at ${TARGET}"
  say "    after dragging Anymatix to Applications you can eject it and delete the file."
  exit 0
fi

# ------------------------------------------------------------------ install ---

APPS_DIR="/Applications"
MOUNT_DEV=""
STAGE=""

# Whatever happens next — a refusal, a failed copy, Ctrl-C — the image gets
# ejected and a half-made copy gets removed. An abandoned /Volumes entry is
# somebody's puzzle three weeks later.
cleanup() {
  if [ -n "${STAGE:-}" ] && [ -e "$STAGE" ]; then
    rm -rf "$STAGE" 2>/dev/null || true
  fi
  if [ -n "${MOUNT_DEV:-}" ]; then
    hdiutil detach "$MOUNT_DEV" -quiet 2>/dev/null \
      || hdiutil detach "$MOUNT_DEV" -force -quiet 2>/dev/null \
      || true
    MOUNT_DEV=""
  fi
}
trap cleanup EXIT
trap 'cleanup; exit 130' INT TERM

step "Mounting the disk image"

# -nobrowse keeps it out of the Finder sidebar: this mount is the installer's
# business and is gone in a moment. The mount point is READ OUT OF hdiutil's
# own output and never guessed — it carries the version and the architecture
# ("Anymatix 1.0.0-beta.12-arm64" today), so any name written down here would
# be wrong at the next release.
ATTACH_OUT="$(hdiutil attach -nobrowse -readonly "$TARGET" 2>&1)" \
  || die "could not mount ${TARGET}. hdiutil said: ${ATTACH_OUT}"

MOUNT_POINT="$(printf '%s\n' "$ATTACH_OUT" | sed -n 's|^.*[[:space:]]\(/Volumes/.*\)$|\1|p' | head -n 1)"
MOUNT_DEV="$(printf '%s\n' "$ATTACH_OUT" | awk 'index($0, "/Volumes/") { print $1; exit }')"

[ -n "$MOUNT_POINT" ] && [ -d "$MOUNT_POINT" ] \
  || die "the disk image mounted but hdiutil named no volume this script could find. Open ${TARGET} in Finder and drag Anymatix to Applications yourself."

say "    mounted at ${MOUNT_POINT}"

APP_SRC="$(find "$MOUNT_POINT" -maxdepth 1 -name '*.app' -print 2>/dev/null | head -n 1)"
[ -n "$APP_SRC" ] || die "there is no application in ${MOUNT_POINT} — this disk image is not the one this script expected. Open it in Finder and look."

APP_NAME="$(basename "$APP_SRC")"
APP_BASE="${APP_NAME%.app}"
DEST="${APPS_DIR}/${APP_NAME}"
say "    found ${APP_NAME}"

# ------------------------------------------------------------- may we write ---

[ -d "$APPS_DIR" ] || die "there is no ${APPS_DIR} on this machine, so there is nowhere to install to."

if [ ! -w "$APPS_DIR" ]; then
  die "${APPS_DIR} is not writable by your account, and this script never uses sudo. The disk image is mounted at ${MOUNT_POINT} — drag ${APP_NAME} into ${APPS_DIR} in Finder, which will ask for an administrator password itself. Or install into your own account instead: cp -R '${APP_SRC}' ~/Applications/"
fi

# ---------------------------------------------------- is it running already ---

# Two things make `pgrep -f <bundle path>` the wrong question here, both
# measured on this machine on 2026-09-20:
#
#  * Anymatix forks children out of the SAME executable — its MCP actions
#    server runs as `…/MacOS/Anymatix …/Resources/app.asar/out/main/mcp/…` —
#    and those children can OUTLIVE the app. Two of them were still there
#    after the app had quit, so a path match called a quit app running and the
#    installer would sit asking somebody to quit what they already had.
#  * The main process does not always carry its path at all: launched through
#    LaunchServices it appeared in `ps` as plain `Anymatix 1.0.0-beta.12`.
#
# So three signals, any of which means running, and none of which the leftover
# children satisfy: a process under this bundle's Contents that is not one of
# those children — the GPU, renderer and utility helpers always carry the real
# bundle path — or a process whose whole command is the app's own name.
app_is_running() {
  ps -axo command= 2>/dev/null | awk -v pfx="${DEST}/Contents/" -v name="${APP_BASE}" '
    index($0, pfx) == 1 && index($0, "/Contents/Resources/") == 0 { found = 1 }
    $0 == name || index($0, name " ") == 1                        { found = 1 }
    END { exit (found ? 0 : 1) }
  '
}

if [ -d "$DEST" ] && app_is_running; then
  step "${APP_NAME} is running"
  say "    ${DEST} is open right now, and an app cannot be replaced while it is"
  say "    running — it would keep using the old files until you quit it, and"
  say "    may crash on the way. Quit Anymatix (Cmd-Q, or Quit from its menu)."
  say ""
  say "    ============================================================"
  say "    QUIT ANYMATIX, THEN PRESS ENTER — OR TYPE cancel TO STOP HERE"
  say "    ============================================================"

  if ! { exec 4</dev/tty; } 2>/dev/null; then
    die "${APP_NAME} is running and there is no terminal to ask you to quit it on. Nothing was changed. Quit Anymatix and run the command again."
  fi

  while app_is_running; do
    printf '> ' > /dev/tty
    if ! IFS= read -r REPLY <&4; then
      die "${APP_NAME} is still running. Nothing was changed."
    fi
    case "$REPLY" in
      [Cc][Aa][Nn][Cc][Ee][Ll]) die "${APP_NAME} is still running and you asked to stop. Nothing was changed." ;;
      *)
        if app_is_running; then
          say "    ${APP_NAME} is still running. Quit it and press Enter again."
        fi
        ;;
    esac
  done

  exec 4<&-
  say "    thank you — it has quit."
fi

# --------------------------------------------------------------------- copy ---

step "Copying ${APP_NAME} into ${APPS_DIR}"
say "    a few hundred megabytes — this takes a moment."

# Staged under a dot-name and renamed in only once the packaging check has
# passed. The Anymatix you already have is therefore never the thing being
# tested: it is replaced, in one rename, by a copy already known to be sound.
STAGE="${APPS_DIR}/.anymatix-install-$$.app"
rm -rf "$STAGE"
ditto "$APP_SRC" "$STAGE" \
  || die "could not copy ${APP_NAME} into ${APPS_DIR}. Nothing was changed."

step "Clearing the quarantine flag on the installed copy"
xattr -dr com.apple.quarantine "$STAGE" 2>/dev/null || true

# ------------------------------------------------------- is the app whole ---

step "Checking the package is whole"
say "    reading the app.asar directory for /node_modules/fs-extra/package.json."

if asar_has_top_level_fs_extra "${STAGE}/Contents/Resources/app.asar"; then
  say "    /node_modules/fs-extra/package.json is there at the top level — good."
else
  rm -rf "$STAGE"
  STAGE=""
  die "this build of ${APP_NAME} is BROKEN and has not been installed. Its app.asar has no /node_modules/fs-extra/package.json at the top level, which means its dependencies were packed wrongly and the app would die at launch with \"Cannot find module 'fs-extra'\". The copy has been deleted and ${DEST} was left as it was. This is a mistake in the release, not on your machine — report it, and install an earlier build from https://github.com/${REPO}/releases in the meantime."
fi

# ------------------------------------------------------------------- swap in ---

if [ -e "$DEST" ]; then
  step "Replacing the ${APP_NAME} already in ${APPS_DIR}"
  rm -rf "$DEST" || die "could not remove the existing ${DEST}. Nothing was changed — the new copy is at ${STAGE}."
fi

mv "$STAGE" "$DEST" || die "could not move the new copy into place. It is at ${STAGE}; move it to ${DEST} yourself."
STAGE=""

step "Ejecting the disk image"
hdiutil detach "$MOUNT_DEV" -quiet 2>/dev/null \
  || hdiutil detach "$MOUNT_DEV" -force -quiet 2>/dev/null \
  || say "    the image would not eject; eject it from Finder."
MOUNT_DEV=""

# --------------------------------------------------------------- the download ---

if [ -n "$LOCAL_IMAGE" ]; then
  :
elif [ "$DELETE_DOWNLOAD" = 1 ]; then
  step "Deleting the downloaded disk image (--delete-download)"
  rm -f "$TARGET"
  rmdir "$TARGET_DIR" 2>/dev/null || true
  say "    gone."
else
  step "Keeping the downloaded disk image"
  say "    it is at ${TARGET}"
  say "    delete it whenever you like, or pass --delete-download next time."
fi

# -------------------------------------------------------------------- launch ---

if [ "$DO_LAUNCH" = 0 ]; then
  step "Done"
  say "    ${APP_NAME} is installed at ${DEST} (--no-launch: not started)."
  exit 0
fi

# `open "$DEST"` and not `open -a "$DEST"`. With -a, open asks LaunchServices
# for "the application called this", and on 2026-09-20 that started a DIFFERENT
# copy of Anymatix that LaunchServices still had registered elsewhere on the
# machine — the freshly installed one sat there unused. Given the bundle as a
# path, open launches that bundle.
open "$DEST" || die "${APP_NAME} is installed at ${DEST} but would not start. Open it from Finder."

step "Done"
say "    ${APP_NAME} is installed at ${DEST} and has been started."

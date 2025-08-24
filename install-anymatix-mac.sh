#!/usr/bin/env bash
set -euo pipefail

# Anymatix Beta Installer (macOS Apple Silicon)
# PRIVATE REPO SUPPORT (NO PROMPTS)
# This repository is private. Script logic:
# 1. If gh present and authenticated (gh auth status), use it.
# 2. Else auto-download an ephemeral gh (darwin arm64) into temp dir and test auth.
# 3. If gh not authenticated AND no GITHUB_TOKEN env var -> abort with instructions (no prompts).
# 4. If GITHUB_TOKEN provided, use curl with token (no interactive flow).
#
# What this script does:
# 1. Determine release tag (latest or ANYMATIX_TAG)
# 2. Download arm64 DMG (preferred) or arm64 zip via authenticated request
# 3. Strip quarantine & install to /Applications
# 4. Verify codesign status (expected unsigned)
#
# Environment overrides:
#   ANYMATIX_TAG=v1.x.x        Use specific tag
#   ANYMATIX_ASSET=pattern     Override asset match (glob, e.g. '*arm64-mac.zip')
#   GITHUB_TOKEN=...           Token if gh not installed

REPO="anymatix/anymatix-beta"
APP_NAME="Anymatix.app"
WORKDIR="$(mktemp -d -t anymatix-beta-XXXXXX)"
DMG_FILE=""

echo "==> Working directory: $WORKDIR"

have_cmd() { command -v "$1" >/dev/null 2>&1; }

need_auth_msg() {
  cat >&2 <<'EOF'
ERROR: Authentication required (no prompts allowed).
Provide a token and re-run:
  export GITHUB_TOKEN=YOUR_TOKEN   # scopes: repo
EOF
}

ensure_ephemeral_gh() {
  # Download latest gh release (public) if gh not on PATH
  if have_cmd gh; then
    GH_BIN="$(command -v gh)"
    return 0
  fi
  echo "==> gh not found; downloading ephemeral GitHub CLI"
  local api="https://api.github.com/repos/cli/cli/releases/latest"
  local tag
  tag=$(curl -fsSL "$api" | grep '"tag_name"' | head -n1 | sed -E 's/.*"tag_name" *: *"([^"]+)".*/\1/' || true)
  if [ -z "$tag" ]; then
    echo "ERROR: Cannot resolve gh latest version" >&2; return 1
  fi
  local tar="gh_${tag#v}_darwin_arm64.tar.gz"
  local url="https://github.com/cli/cli/releases/download/$tag/$tar"
  echo "==> Fetching $url"
  curl -fsSL -o "$WORKDIR/$tar" "$url"
  tar -xzf "$WORKDIR/$tar" -C "$WORKDIR" || return 1
  local extracted_dir
  extracted_dir=$(find "$WORKDIR" -maxdepth 1 -type d -name "gh_*_darwin_arm64" | head -n1)
  if [ -z "$extracted_dir" ]; then
    echo "ERROR: gh extraction failed" >&2; return 1
  fi
  GH_BIN="$extracted_dir/bin/gh"
  chmod +x "$GH_BIN" || true
}

GH_BIN=""

api_get_latest_tag() {
  if [ -n "$GH_BIN" ] && "$GH_BIN" auth status >/dev/null 2>&1; then
    "$GH_BIN" release list --repo "$REPO" --limit 1 --json tagName --jq '.[0].tagName' 2>/dev/null && return 0
  fi
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    curl -sSL -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/repos/$REPO/releases" \
      | grep '"tag_name"' | head -n1 | sed -E 's/.*"tag_name" *: *"([^"]+)".*/\1/' && return 0
  fi
  need_auth_msg; return 1
}

tag="${ANYMATIX_TAG:-$(api_get_latest_tag)}"
if [ -z "$tag" ]; then
  echo "ERROR: Could not determine latest release tag. Set ANYMATIX_TAG manually." >&2
  exit 1
fi

echo "==> Latest tag: $tag"

echo "==> Fetching release asset list"
ensure_ephemeral_gh || true

if [ -n "$GH_BIN" ] && "$GH_BIN" auth status >/dev/null 2>&1; then
  assets_json="$("$GH_BIN" api repos/$REPO/releases/tags/$tag --jq '.assets')"
elif [ -n "${GITHUB_TOKEN:-}" ]; then
  assets_json="$(curl -sSL -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/repos/$REPO/releases/tags/$tag" | grep '"browser_download_url"' || true)"
else
  need_auth_msg; exit 1
fi

# Try to find arm64 dmg first
pattern="${ANYMATIX_ASSET:-}" 
if [ -n "$pattern" ]; then
  asset_url="$(echo "$assets_json" | grep -Eo "https://[^\"]+$pattern" | head -n1 || true)"
else
  asset_url="$(echo "$assets_json" | grep -Eo 'https://[^"[:space:]]+anymatix-[0-9A-Za-z_.-]+\.dmg' | head -n1)"
  if [ -z "$asset_url" ]; then
    asset_url="$(echo "$assets_json" | grep -Eo 'https://[^"[:space:]]+\.dmg' | head -n1)"
  fi
  if [ -z "$asset_url" ]; then
    asset_url="$(echo "$assets_json" | grep -Eo 'https://[^"[:space:]]+Anymatix-[0-9A-Za-z_.-]+-arm64-mac\.zip' | head -n1)"
  fi
fi

if [ -z "$asset_url" ]; then
  echo "ERROR: Could not locate a macOS asset (.dmg or zip) in release $tag" >&2
  exit 1
fi

echo "==> Downloading asset: $asset_url"
cd "$WORKDIR"
filename="${asset_url##*/}"
if [ -n "$GH_BIN" ] && "$GH_BIN" auth status >/dev/null 2>&1; then
  if ! "$GH_BIN" release download "$tag" --repo "$REPO" --pattern "$filename" -O "$filename" 2>/dev/null; then
    echo "gh release download failed; fallback curl"
    curl -L --fail -H "Authorization: Bearer ${GITHUB_TOKEN:-}" -o "$filename" "$asset_url"
  fi
else
  curl -L --fail -H "Authorization: Bearer ${GITHUB_TOKEN:-}" -o "$filename" "$asset_url"
fi

echo "==> Download complete: $filename"

if [[ "$filename" == *.dmg ]]; then
  DMG_FILE="$filename"
  echo "==> Mounting DMG"
  MOUNT_POINT=$(hdiutil attach "$DMG_FILE" -nobrowse -quiet | grep -Eo '/Volumes/[^']*' | head -n1)
  if [ -z "$MOUNT_POINT" ]; then
    echo "ERROR: Could not mount DMG" >&2
    exit 1
  fi
  echo "==> Mounted at $MOUNT_POINT"
  if [ ! -d "$MOUNT_POINT/$APP_NAME" ]; then
    echo "ERROR: $APP_NAME not found inside DMG" >&2
    hdiutil detach "$MOUNT_POINT" -quiet || true
    exit 1
  fi
  echo "==> Copying app to /Applications (may require sudo if permissions restricted)"
  cp -R "$MOUNT_POINT/$APP_NAME" /Applications/
  echo "==> Detaching DMG"
  hdiutil detach "$MOUNT_POINT" -quiet || true
else
  echo "==> Treating as zip archive"
  unzip -q "$filename"
  found_app=$(find . -maxdepth 3 -name "$APP_NAME" -type d | head -n1)
  if [ -z "$found_app" ]; then
    echo "ERROR: Could not find $APP_NAME in extracted zip" >&2
    exit 1
  fi
  echo "==> Copying app to /Applications"
  cp -R "$found_app" /Applications/
fi

TARGET_APP="/Applications/$APP_NAME"
if [ ! -d "$TARGET_APP" ]; then
  echo "ERROR: Installation failed: $TARGET_APP missing" >&2
  exit 1
fi

echo "==> Removing quarantine attribute (requires permission)"
xattr -dr com.apple.quarantine "$TARGET_APP" || true

echo "==> Verifying app bundle"
if codesign -dv "$TARGET_APP" >/dev/null 2>&1; then
  codesign -dv --verbose=4 "$TARGET_APP" 2>&1 | grep -E 'Identifier|Format|CodeDirectory v|Signature|Runtime' || true
else
  echo "(Not signed; this is expected for unsigned beta)"
fi

echo "==> Done. Launch via: open -a Anymatix"

echo "If macOS still warns the app is damaged, run:"
echo "  xattr -dr com.apple.quarantine /Applications/Anymatix.app"
echo "and launch again via right-click -> Open"

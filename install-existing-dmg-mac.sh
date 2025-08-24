#!/usr/bin/env bash
set -euo pipefail

# Local DMG installer for Anymatix (assumes DMG already downloaded into current directory)
# Usage: place this script and the anymatix-*.dmg in the same folder, then run:
#   ./install-existing-dmg-mac.sh
# It will:
#  - pick the newest anymatix*.dmg (or use ANYMATIX_DMG)
#  - remove quarantine from DMG
#  - mount DMG
#  - copy Anymatix.app to /Applications
#  - remove quarantine from installed app
#  - optionally strip stale ad-hoc signature and re-sign ad-hoc cleanly (can disable via ANYMATIX_RESIGN=0)
#  - verify with spctl
# Environment vars:
#   ANYMATIX_DMG=filename.dmg   # explicitly pick a DMG
#   ANYMATIX_RESIGN=0           # skip ad-hoc re-sign step

APP_NAME="Anymatix.app"
DMG="${ANYMATIX_DMG:-}"
RESIGN="${ANYMATIX_RESIGN:-1}"

if [ -z "$DMG" ]; then
  DMG=$(ls -1t anymatix*.dmg 2>/dev/null | head -n1 || true)
fi

if [ -z "$DMG" ] || [ ! -f "$DMG" ]; then
  echo "ERROR: Could not find anymatix*.dmg in current directory (or specified ANYMATIX_DMG missing)." >&2
  exit 1
fi

echo "==> Using DMG: $DMG"

# Remove quarantine from DMG if present
if xattr "$DMG" 2>/dev/null | grep -q com.apple.quarantine; then
  echo "==> Removing quarantine from DMG"
  xattr -d com.apple.quarantine "$DMG" || true
fi

# Mount DMG
echo "==> Mounting DMG"
MOUNT_OUT=$(hdiutil attach "$DMG" -nobrowse) || { echo "ERROR: Failed to mount DMG" >&2; exit 1; }
MOUNT_POINT=$(echo "$MOUNT_OUT" | awk 'END{print $NF}')
if [ ! -d "$MOUNT_POINT/$APP_NAME" ]; then
  echo "ERROR: $APP_NAME not found inside mounted DMG ($MOUNT_POINT)" >&2
  hdiutil detach "$MOUNT_POINT" >/dev/null 2>&1 || true
  exit 1
fi

echo "==> Copying app to /Applications (may need password if restricted)"
cp -R "$MOUNT_POINT/$APP_NAME" /Applications/

echo "==> Detaching DMG"
hdiutil detach "$MOUNT_POINT" >/dev/null 2>&1 || true

TARGET_APP="/Applications/$APP_NAME"
if [ ! -d "$TARGET_APP" ]; then
  echo "ERROR: Install failed (app not in /Applications)." >&2
  exit 1
fi

# Remove quarantine from installed app
if xattr "$TARGET_APP" 2>/dev/null | grep -q com.apple.quarantine; then
  echo "==> Removing quarantine from installed app"
  xattr -dr com.apple.quarantine "$TARGET_APP" || true
fi

# Strip existing ad-hoc signature if present (it can cause damaged message)
echo "==> Stripping existing code signature (if any)"
codesign --remove-signature "$TARGET_APP" 2>/dev/null || true

if [ "$RESIGN" = "1" ]; then
  echo "==> Re-signing ad-hoc (clean)"
  codesign --force --deep --sign - "$TARGET_APP" || echo "(ad-hoc re-sign failed; continuing)"
else
  echo "==> Skipping ad-hoc re-sign (ANYMATIX_RESIGN=0)"
fi

# Verify
echo "==> spctl assessment (expected failure or warnings for unsigned builds is fine)"
spctl --assess -vv "$TARGET_APP" 2>&1 || true

echo "==> codesign details (for debugging)"
codesign -dv --verbose=2 "$TARGET_APP" 2>&1 || true

echo "==> Done. Launch with: open -a Anymatix"
echo "If macOS shows damaged warning still:"
echo "  xattr -dr com.apple.quarantine /Applications/Anymatix.app"
echo "  open -a Anymatix"

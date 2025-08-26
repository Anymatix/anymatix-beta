#!/bin/bash

# Script to generate README.md from template using COMFYUI_VERSION.txt from main repo
# This ensures the README always reflects the correct version for releases

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BETA_REPO_DIR="$SCRIPT_DIR"
MAIN_REPO_DIR="$(cd "$SCRIPT_DIR/../../" && pwd)"
COMFYUI_VERSION_FILE="$MAIN_REPO_DIR/app/COMFYUI_VERSION.txt"
TEMPLATE_FILE="$BETA_REPO_DIR/README.template.md"
OUTPUT_FILE="$BETA_REPO_DIR/README.md"

echo "Beta repo directory: $BETA_REPO_DIR"
echo "Main repo directory: $MAIN_REPO_DIR"
echo "COMFYUI version file: $COMFYUI_VERSION_FILE"

# Check if COMFYUI_VERSION.txt exists
if [[ ! -f "$COMFYUI_VERSION_FILE" ]]; then
    echo "Error: COMFYUI_VERSION.txt not found at $COMFYUI_VERSION_FILE"
    exit 1
fi

# Check if template exists
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo "Error: README.template.md not found at $TEMPLATE_FILE"
    exit 1
fi

# Read the version from COMFYUI_VERSION.txt (trim whitespace)
VERSION=$(cat "$COMFYUI_VERSION_FILE" | tr -d '[:space:]')

if [[ -z "$VERSION" ]]; then
    echo "Error: Version is empty in $COMFYUI_VERSION_FILE"
    exit 1
fi

echo "Using version: $VERSION"

# Generate README.md by replacing {{VERSION}} placeholders
sed "s/{{VERSION}}/$VERSION/g" "$TEMPLATE_FILE" > "$OUTPUT_FILE"

echo "✅ Generated $OUTPUT_FILE with version $VERSION"
echo "📝 README.md updated successfully"

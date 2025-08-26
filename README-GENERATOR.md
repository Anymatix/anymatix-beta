# README Generation System

This directory contains an automated README generation system for the anymatix-beta repository.

## Overview

The system ensures that the README.md always reflects the correct version for releases by reading the version from `COMFYUI_VERSION.txt` in the main repository and generating the README from a template.

## Files

- **README.template.md** - Template file with `{{VERSION}}` placeholders
- **generate-readme.sh** - Bash script for generating README
- **generate-readme.js** - Node.js script for generating README (cross-platform)
- **package.json** - NPM configuration with scripts
- **README.md** - Generated output file (do not edit manually)

## Usage

### Option 1: Using npm (recommended)
```bash
cd submodules/anymatix-beta
npm run generate-readme
```

### Option 2: Using bash directly
```bash
cd submodules/anymatix-beta
./generate-readme.sh
```

### Option 3: Using Node.js directly
```bash
cd submodules/anymatix-beta
node generate-readme.js
```

## How it works

1. Reads version from `../../app/COMFYUI_VERSION.txt` (main repo)
2. Loads `README.template.md`
3. Replaces all `{{VERSION}}` placeholders with the actual version
4. Writes the result to `README.md`

## Integration with Release Process

This script should be run as part of the release process to ensure the README always has the correct download links and version references.

You can integrate it into your build/release scripts by calling:
```bash
cd submodules/anymatix-beta && npm run generate-readme
```

## Template Variables

Currently supported template variables:
- `{{VERSION}}` - Replaced with the version from COMFYUI_VERSION.txt

## Error Handling

The script will exit with an error if:
- COMFYUI_VERSION.txt is not found
- README.template.md is not found  
- Version string is empty
- File read/write permissions are insufficient

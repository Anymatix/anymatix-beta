# README Generation System

This directory contains an automated README generation system for the anymatix-beta repository.

## Overview

The system ensures that the README.md always reflects the correct version for releases by reading the version from `package.json` in the main repository and generating the README from a template.

## Files

- **README.template.md** - Template file with `{{VERSION}}` placeholders
- **generate-readme.js** - Node.js script for generating README
- **package.json** - NPM configuration with scripts
- **README.md** - Generated output file (do not edit manually)

## Usage

### Using npm (recommended)
```bash
cd submodules/anymatix-beta
npm run generate-readme
```

### Using Node.js directly
```bash
cd submodules/anymatix-beta
node generate-readme.js
```

## How it works

1. Reads version from `../../app/package.json` (main repo)
2. Loads `README.template.md`
3. Replaces all `{{VERSION}}` placeholders with the actual version
4. Writes the result to `README.md`

## Integration with Release Process

This script is automatically called by the main release script (`yarn release` in the main app) to ensure the README always has the correct download links and version references.

The release script will:
1. Generate the README with the correct version
2. Commit and push the changes to the anymatix-beta repository
3. Create and push the release tag

## Template Variables

Currently supported template variables:
- `{{VERSION}}` - Replaced with the version from the main app's package.json

## Error Handling

The script will exit with an error if:
- package.json is not found in the main repo
- README.template.md is not found  
- Version string is empty
- File read/write permissions are insufficient

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
````markdown
# README generator (concise)

Generates `README.md` from `README.template.md` by replacing `{{VERSION}}` with the version read from the main app's `package.json`.

Files
- `generate-readme.js` — generator script
- `README.template.md` — template with `{{VERSION}}`
- `README.md` — generated output (do not edit)

Quick usage

- From the main repo:
	- cd to this folder and run the npm script:

```bash
cd submodules/anymatix-beta
npm run generate-readme
```

- Or run directly with Node:

```bash
cd submodules/anymatix-beta
node generate-readme.js
```

macOS one-liner

This will download the repository ZIP from GitHub, extract the `anymatix-beta` subfolder, and run the generator (replace OWNER/REPO and TAG or use main):

```bash
curl -sL https://github.com/OWNER/REPO/archive/refs/heads/main.zip | bsdtar -xvf- "REPO-main/submodules/anymatix-beta/*" -O | (cd /tmp && unzip -qq - && cd REPO-main/submodules/anymatix-beta && node generate-readme.js)
```

Notes
- The script expects `../../app/package.json` to exist when run inside the cloned repo. If running from a ZIP download, ensure the `app/package.json` is present or adjust the path.
- The generator exits with non-zero code on missing files or empty version.
````

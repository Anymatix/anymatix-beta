#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Script to generate README.md from template using COMFYUI_VERSION.txt from main repo
// This ensures the README always reflects the correct version for releases

const scriptDir = __dirname;
const betaRepoDir = scriptDir;
const mainRepoDir = path.resolve(scriptDir, '../../');
const comfyuiVersionFile = path.join(mainRepoDir, 'app', 'COMFYUI_VERSION.txt');
const templateFile = path.join(betaRepoDir, 'README.template.md');
const outputFile = path.join(betaRepoDir, 'README.md');

console.log('Beta repo directory:', betaRepoDir);
console.log('Main repo directory:', mainRepoDir);
console.log('COMFYUI version file:', comfyuiVersionFile);

// Check if COMFYUI_VERSION.txt exists
if (!fs.existsSync(comfyuiVersionFile)) {
    console.error(`Error: COMFYUI_VERSION.txt not found at ${comfyuiVersionFile}`);
    process.exit(1);
}

// Check if template exists
if (!fs.existsSync(templateFile)) {
    console.error(`Error: README.template.md not found at ${templateFile}`);
    process.exit(1);
}

// Read the version from COMFYUI_VERSION.txt (trim whitespace)
const version = fs.readFileSync(comfyuiVersionFile, 'utf8').trim();

if (!version) {
    console.error(`Error: Version is empty in ${comfyuiVersionFile}`);
    process.exit(1);
}

console.log('Using version:', version);

// Read template and replace {{VERSION}} placeholders
const template = fs.readFileSync(templateFile, 'utf8');
const output = template.replace(/\{\{VERSION\}\}/g, version);

// Write the generated README.md
fs.writeFileSync(outputFile, output);

console.log(`✅ Generated ${outputFile} with version ${version}`);
console.log('📝 README.md updated successfully');

#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Script to generate README.md from template using the main app version from package.json
// This ensures the README always reflects the correct version for releases

const scriptDir = __dirname;
const betaRepoDir = scriptDir;
const mainRepoDir = path.resolve(scriptDir, '../../');
const packageJsonFile = path.join(mainRepoDir, 'app', 'package.json');
const templateFile = path.join(betaRepoDir, 'README.template.md');
const outputFile = path.join(betaRepoDir, 'README.md');

console.log('Beta repo directory:', betaRepoDir);
console.log('Main repo directory:', mainRepoDir);
console.log('Package.json file:', packageJsonFile);

// Check if package.json exists
if (!fs.existsSync(packageJsonFile)) {
    console.error(`Error: package.json not found at ${packageJsonFile}`);
    process.exit(1);
}

// Check if template exists
if (!fs.existsSync(templateFile)) {
    console.error(`Error: README.template.md not found at ${templateFile}`);
    process.exit(1);
}

// Read the version from package.json
const packageJson = JSON.parse(fs.readFileSync(packageJsonFile, 'utf8'));
const version = packageJson.version;

if (!version) {
    console.error(`Error: Version is missing in ${packageJsonFile}`);
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

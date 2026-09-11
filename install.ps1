# Anymatix installer - Windows.
#
#   irm https://raw.githubusercontent.com/Anymatix/anymatix-beta/main/install.ps1 | iex
#
# What it does: asks GitHub for the LATEST Anymatix release, picks the installer
# that matches this processor, downloads it into a directory of its own, clears
# the internet-zone mark Windows puts on anything downloaded, and runs the
# installer. The installer itself is what asks where Anymatix goes.
#
# No version is written down anywhere in this file. The release it fetches is
# whatever /releases/latest returns on the day you run it.
#
# It never asks for administrator rights and writes only inside the download
# directory it creates. Windows SmartScreen may still warn about an unsigned
# installer - the beta builds are unsigned, and clearing the zone mark is what
# keeps that warning to one click instead of a refusal.
#
# Maintained in the anymatix superproject and published from there to
# github.com/Anymatix/anymatix-beta. Edit it there, not here.

# The equivalent of `set -eu`: any error stops the script instead of letting a
# half-run installation continue.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # the built-in progress bar makes Invoke-WebRequest crawl

$Repo = 'Anymatix/anymatix-beta'
$Api  = "https://api.github.com/repos/$Repo/releases/latest"

function Say  { param($Message) Write-Host "    $Message" }
function Step { param($Message) Write-Host ""; Write-Host "==> $Message" }
function Die  { param($Message) Write-Host ""; Write-Host "Anymatix installer: $Message" -ForegroundColor Red; exit 1 }

# ---------------------------------------------------------------- platform ---

Step 'Looking at this machine'

$Arch = $env:PROCESSOR_ARCHITECTURE
if ($env:PROCESSOR_ARCHITEW6432) { $Arch = $env:PROCESSOR_ARCHITEW6432 }
Say "system:    Windows"
Say "processor: $Arch"

# The asset pattern is matched against the release's asset names, so an arm64
# installer published later is found WITHOUT AN EDIT to this script.
switch -Regex ($Arch) {
    '^(AMD64|x86)$' { $AssetPattern = '(?i)setup\.exe$' }
    '^ARM64$'       { $AssetPattern = '(?i)(arm64.*setup\.exe|setup\.exe)$' }
    default         { Die "Anymatix has no Windows build for a $Arch processor." }
}

if ($PSVersionTable.PSVersion.Major -lt 5) {
    Die 'this needs Windows PowerShell 5 or newer. Open the Start menu, type PowerShell, and use the one Windows ships.'
}

# ------------------------------------------------------------------ release ---

Step 'Asking GitHub for the latest Anymatix release'

try {
    $Release = Invoke-RestMethod -Uri $Api -Headers @{ 'Accept' = 'application/vnd.github+json'; 'User-Agent' = 'anymatix-installer' }
} catch {
    Die "could not reach the GitHub releases API. Check the network and try again. ($($_.Exception.Message))"
}

if (-not $Release -or -not $Release.tag_name) {
    Die 'GitHub returned no latest release - nothing to install.'
}

$Tag = $Release.tag_name
Say "latest release: $Tag"

$Asset = $Release.assets | Where-Object { $_.name -match $AssetPattern } | Select-Object -First 1

if (-not $Asset) {
    Die "release $Tag has no Windows installer for $Arch. Pick a file by hand at https://github.com/$Repo/releases/latest"
}

Say "asset:          $($Asset.name)"

# ----------------------------------------------------------------- download ---

$DownloadRoot = Join-Path $env:USERPROFILE 'Downloads'
if (-not (Test-Path -LiteralPath $DownloadRoot)) { $DownloadRoot = (Get-Location).Path }
$TargetDir = Join-Path $DownloadRoot "anymatix-$Tag"
$Target    = Join-Path $TargetDir $Asset.name

Step "Downloading into $TargetDir"
Say 'this is a large file - half a gigabyte or so. It will take a while.'

New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null

try {
    Invoke-WebRequest -Uri $Asset.browser_download_url -OutFile $Target -UseBasicParsing -Headers @{ 'User-Agent' = 'anymatix-installer' }
} catch {
    Die "the download did not complete. Run the same command again. ($($_.Exception.Message))"
}

if (-not (Test-Path -LiteralPath $Target)) {
    Die "the download produced no file at $Target."
}

# A connection that closes cleanly mid-file leaves a short file and no error, so
# compare against the size GitHub advertised rather than trusting the exit.
$Actual = (Get-Item -LiteralPath $Target).Length
if ($Asset.size -and $Actual -ne $Asset.size) {
    Die "the download is incomplete: $Actual bytes of $($Asset.size). Delete $Target and run the same command again."
}
Say "downloaded $Actual bytes, which is the whole file."

# ------------------------------------------------------------------- unlock ---

Step 'Clearing the internet-zone mark Windows puts on downloaded files'
Say 'Anymatix beta builds are unsigned, so without this Windows refuses to run the installer.'
Unblock-File -LiteralPath $Target

Step 'Running the installer'
try {
    Start-Process -FilePath $Target
} catch {
    Die "could not start the installer. Run it by hand: $Target"
}

Step 'Done'
Say "the installer is at $Target"
Say 'if SmartScreen warns that the publisher is unknown, choose More info and then Run anyway.'

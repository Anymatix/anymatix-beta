# Anymatix installer - Windows.
#
#   irm https://raw.githubusercontent.com/Anymatix/anymatix-beta/main/install.ps1 | iex
#
# What it does: asks GitHub for the LATEST Anymatix release, picks the installer
# that matches this processor, downloads it into a directory of its own,
# VERIFIES ITS SHA-256 against the SHA256SUMS.txt the release publishes, clears
# the internet-zone mark Windows puts on anything downloaded, and runs the
# installer. The installer itself is what asks where Anymatix goes.
#
# The checksum is not a nicety, it is the only check that can be trusted. Size
# says how much arrived; only the hash says WHAT arrived. On 2026-09-20 the
# macOS script handed over a corrupt disk image that was exactly the right
# number of bytes - a part-file left by a DIFFERENT build of the same version,
# completed by a resumed download - and the size check saw nothing wrong. So: a
# file whose hash does not match the published one is deleted and fetched once
# more from scratch, and if the release publishes no SHA256SUMS.txt - or no
# line for this file - the script refuses rather than hand over something it
# cannot verify.
#
# No version is written down anywhere in this file. The release it fetches is
# whatever /releases/latest returns on the day you run it.
#
# It never asks for administrator rights and writes only inside the download
# directory it creates. Windows SmartScreen may still warn about an unsigned
# installer - the beta builds are unsigned, and clearing the zone mark is what
# keeps that warning to one click instead of a refusal.
#
# Before it downloads anything it asks you to accept the Beta Tester Voluntary
# Contributor Agreement (the terms of the beta), and prints the URL where the
# same text lives online. Press Enter to accept, or type cancel to refuse - a
# refusal exits without downloading anything. For unattended runs (CI, a
# provisioning script) where nobody is at the prompt to answer, set
# $env:ANYMATIX_ACCEPT_TERMS = '1' to accept the agreement non-interactively;
# with no terminal to ask on, the script otherwise refuses by default rather
# than guessing.
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
$AgreementUrl = 'https://anymatix-2925e.web.app/beta-agreement'

function Say  { param($Message) Write-Host "    $Message" }
function Step { param($Message) Write-Host ""; Write-Host "==> $Message" }
function Die  { param($Message) Write-Host ""; Write-Host "Anymatix installer: $Message" -ForegroundColor Red; exit 1 }

# ------------------------------------------------------------------- terms ---

function Test-TermsGate {
    if ($env:ANYMATIX_ACCEPT_TERMS -eq '1') {
        Step 'Beta Tester Voluntary Contributor Agreement'
        Say "the terms: $AgreementUrl"
        Say 'accepted automatically (ANYMATIX_ACCEPT_TERMS=1).'
        return
    }

    Step 'Beta Tester Voluntary Contributor Agreement'
    Say "read the terms: $AgreementUrl"
    Say ''
    Say '============================================================'
    Say 'PRESS ENTER IF YOU ACCEPT THE TERMS, OR TYPE cancel TO REFUSE'
    Say '============================================================'

    if (-not [Environment]::UserInteractive) {
        Die "no terminal to ask for consent on (this looks like a non-interactive run, e.g. CI) - refusing by default. Terms refused. Nothing was downloaded. To automate this, accept the agreement above and re-run with `$env:ANYMATIX_ACCEPT_TERMS = '1'`."
    }

    while ($true) {
        try {
            $Reply = Read-Host '>'
        } catch {
            Die 'Terms refused. Nothing was downloaded.'
        }
        if ([string]::IsNullOrEmpty($Reply)) { return }
        if ($Reply.Trim().ToLowerInvariant() -eq 'cancel') { Die 'Terms refused. Nothing was downloaded.' }
        Say 'please press Enter to accept, or type cancel to refuse.'
    }
}

Test-TermsGate

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

# ----------------------------------------------------------------- checksum ---

# Resolved BEFORE the download: refusing after a quarter of a gigabyte has
# arrived would be rude, and there is nothing this script can do with an
# unverifiable asset except refuse it.
Step 'Asking GitHub for the published checksums'

$SumsAsset = $Release.assets | Where-Object { $_.name -eq 'SHA256SUMS.txt' } | Select-Object -First 1

if (-not $SumsAsset) {
    Die "release $Tag publishes no SHA256SUMS.txt, so there is nothing to verify $($Asset.name) against. Refusing to install an unverified download. Report this - a release without checksums is a mistake in the release, not on your machine."
}

try {
    $SumsText = (Invoke-WebRequest -Uri $SumsAsset.browser_download_url -UseBasicParsing -Headers @{ 'User-Agent' = 'anymatix-installer' }).Content
    if ($SumsText -is [byte[]]) { $SumsText = [System.Text.Encoding]::UTF8.GetString($SumsText) }
} catch {
    Die "could not fetch the published checksums from $($SumsAsset.browser_download_url). Refusing to install an unverified download. Check the network and run the command again. ($($_.Exception.Message))"
}

$ExpectedSha = $null
foreach ($Line in ($SumsText -split "`r?`n")) {
    $Fields = $Line.Trim() -split '\s+'
    if ($Fields.Count -ge 2) {
        $Name = $Fields[-1].TrimStart('*')
        if ($Name -eq $Asset.name) { $ExpectedSha = $Fields[0].ToLowerInvariant(); break }
    }
}

if (-not $ExpectedSha) {
    Die "SHA256SUMS.txt for release $Tag has no line for $($Asset.name), so this download cannot be verified. Refusing to install an unverified download. Report this - the release is incomplete."
}

Say "published sha256: $ExpectedSha"

# ----------------------------------------------------------------- download ---

$DownloadRoot = Join-Path $env:USERPROFILE 'Downloads'
if (-not (Test-Path -LiteralPath $DownloadRoot)) { $DownloadRoot = (Get-Location).Path }
$TargetDir = Join-Path $DownloadRoot "anymatix-$Tag"
$Target    = Join-Path $TargetDir $Asset.name

Step "Downloading into $TargetDir"
Say 'this is a large file - half a gigabyte or so. It will take a while.'

New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null

# Two attempts at most. A file that fails the checksum twice is not a download
# problem, and saying so is more use than fetching it forever.
$Attempt = 1
while ($true) {
    if ($Attempt -gt 1) {
        Step 'Downloading again, from scratch'
        Remove-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    }

    try {
        Invoke-WebRequest -Uri $Asset.browser_download_url -OutFile $Target -UseBasicParsing -Headers @{ 'User-Agent' = 'anymatix-installer' }
    } catch {
        if ($Attempt -gt 1) {
            Die "the second download did not complete either. Delete $Target and run the same command again. ($($_.Exception.Message))"
        }
        Die "the download did not complete. Run the same command again. ($($_.Exception.Message))"
    }

    $Problem = $null
    if (-not (Test-Path -LiteralPath $Target)) {
        $Problem = "the download produced no file at $Target"
    } else {
        # The cheap first signal: a connection that closes cleanly mid-file
        # leaves a short file and no error. It is never the last word.
        $Actual = (Get-Item -LiteralPath $Target).Length
        if ($Asset.size -and $Actual -ne $Asset.size) {
            $Problem = "the file is $Actual bytes where release $Tag says $($Asset.size)"
        } else {
            Say "downloaded $Actual bytes, which is the whole file."

            Step 'Verifying the download against the published checksum'
            $ActualSha = (Get-FileHash -LiteralPath $Target -Algorithm SHA256).Hash.ToLowerInvariant()
            if ($ActualSha -eq $ExpectedSha) {
                Say "checksum verified: sha256 $ActualSha matches the published SHA256SUMS.txt."
                break
            }
            $Problem = "this file does NOT match the published checksum - its sha256 is $ActualSha, and release $Tag publishes $ExpectedSha"
        }
    }

    if ($Attempt -eq 1) {
        Say ''
        Say "$Problem."
        Say 'A file can reach exactly the right size and still be the wrong bytes -'
        Say 'a leftover from another build of the same version is all it takes.'
        Say 'Deleting it and downloading once more from scratch.'
        $Attempt = 2
        continue
    }

    Die "$Problem - and that was a fresh download. Nothing was installed. Delete $Target and try again; if it happens twice more, something between you and GitHub is altering the file (a proxy or a captive portal will do this), so download it by hand from https://github.com/$Repo/releases/latest and check its SHA-256 against SHA256SUMS.txt yourself with: Get-FileHash <file> -Algorithm SHA256"
}

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

Anymatix Beta
=============

Copy and paste.

**macOS**

```
curl -fsSL https://raw.githubusercontent.com/Anymatix/anymatix-beta/main/install.sh | sh
```

**Windows** — open PowerShell (Start menu > PowerShell) and paste:

```
irm https://raw.githubusercontent.com/Anymatix/anymatix-beta/main/install.ps1 | iex
```

**Linux** — no build yet. The line above works on Linux too, and today it tells
you so and stops rather than downloading something that is not there.

What the line does
------------------

It asks GitHub for the latest Anymatix release, downloads the file for your
system, **checks that file's SHA-256 against the `SHA256SUMS.txt` published
with the release**, clears the flag your system puts on anything downloaded,
and opens it. No version is written into the command, so it never goes stale.

The checksum is the check that matters, and the script prints the line saying
it matched. A download that is the right *size* can still be the wrong *bytes*
— an interrupted attempt is resumed, and a leftover part-file from an earlier
build of the same version can be completed to exactly the right length. If the
hash does not match, the file is deleted and fetched once more from scratch; if
it still does not match, or the release publishes no checksums at all, the
script refuses and installs nothing rather than open a file it cannot vouch
for.

Before any of that it shows the [Beta Tester Voluntary Contributor Agreement](https://anymatix-2925e.web.app/beta-agreement)
and asks you to accept it — press Enter to accept, or type `cancel` to refuse
and exit without downloading anything. For unattended runs, set
`ANYMATIX_ACCEPT_TERMS=1` (`$env:ANYMATIX_ACCEPT_TERMS = '1'` on Windows) to
accept non-interactively.

Anymatix beta builds are **unsigned**. That is the whole reason the flag has to
be cleared: macOS Gatekeeper and Windows SmartScreen both refuse an unsigned
download until you say otherwise. Nothing in these scripts needs a password, and
neither writes outside your Downloads folder.

The scripts are [`install.sh`](install.sh) and [`install.ps1`](install.ps1) in
this repository. Read them before you run them if you would rather — that is why
they are here and not hidden behind a shortener.

Manual download
---------------

Every build is on the [releases page](https://github.com/Anymatix/anymatix-beta/releases/latest):
the `.dmg` for macOS, the `-setup.exe` for Windows.

After downloading by hand you still have to clear the flag yourself:

- **macOS:** `xattr -d com.apple.quarantine ~/Downloads/anymatix-*.dmg` then open the disk image.
- **Windows:** in PowerShell, `Unblock-File ~\Downloads\anymatix-*-setup.exe` then run it.

And check what you downloaded, which the one-liner would have done for you.
Every release carries a `SHA256SUMS.txt`; the number your machine prints must
be the number on the line for your file:

- **macOS / Linux:** `shasum -a 256 ~/Downloads/anymatix-*.dmg`
- **Windows:** `Get-FileHash ~\Downloads\anymatix-*-setup.exe -Algorithm SHA256`

<!--
  This template no longer carries a {{VERSION}} placeholder, and that is the
  point: the install one-liners ask the GitHub releases API for whatever the
  latest release is, so nothing on this page goes stale between releases.
  `generate-readme.js` still runs at publish time and is now a copy, which is
  the honest state — leave it wired so the publish path does not change, and if
  a version ever has to appear here again, put the placeholder back rather than
  editing README.md by hand.
-->

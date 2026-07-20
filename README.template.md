Anymatix Beta
=============


**Windows:** [anymatix-{{VERSION}}-setup.exe](https://github.com/Anymatix/anymatix-beta/releases/download/v{{VERSION}}/anymatix-{{VERSION}}-setup.exe)

and run anyway when prompted by Windows SmartScreen, or read below if it does not start (because SmartScreen blocks it).

**macOS:** [anymatix-{{VERSION}}.dmg](https://github.com/Anymatix/anymatix-beta/releases/download/v{{VERSION}}/anymatix-{{VERSION}}.dmg)

and open anyway when prompted by macOS Gatekeeper, or read below if it does not open (because Gatekeeper blocks it).

Anymatix beta releases are unsigned, so you need to follow special instructions. Manual download is anyway possible (see below).

Windows
-------


Or open PowerShell (Start menu > PowerShell) and paste:
```
curl.exe -L --progress-bar "https://github.com/Anymatix/anymatix-beta/releases/download/v{{VERSION}}/anymatix-{{VERSION}}-setup.exe" -o "anymatix-{{VERSION}}-setup.exe"; Unblock-File "anymatix-{{VERSION}}-setup.exe"; .\anymatix-{{VERSION}}-setup.exe
```

macOS
-----
Open Terminal and paste:
```
curl -LOC- https://github.com/Anymatix/anymatix-beta/releases/download/v{{VERSION}}/anymatix-{{VERSION}}.dmg && xattr -d com.apple.quarantine anymatix-{{VERSION}}.dmg 2>/dev/null || true && open anymatix-{{VERSION}}.dmg
```

Longer explanation
------------------
These beta releases are unsigned, so your system will show security warnings. Windows requires PowerShell's Unblock-File to remove download restrictions. macOS requires a script to remove quarantine flags. The one-liners above handle this automatically.

Manual download
---------------
If you prefer to download manually:

**Windows:** [anymatix-{{VERSION}}-setup.exe](https://github.com/Anymatix/anymatix-beta/releases/download/v{{VERSION}}/anymatix-{{VERSION}}-setup.exe)

**macOS:** [anymatix-{{VERSION}}.dmg](https://github.com/Anymatix/anymatix-beta/releases/download/v{{VERSION}}/anymatix-{{VERSION}}.dmg)

After manual download, Windows users should run PowerShell as administrator and use `Unblock-File` on the downloaded file before running it. macOS users should run `xattr -d com.apple.quarantine anymatix-{{VERSION}}.dmg` to remove quarantine flags before opening the DMG.
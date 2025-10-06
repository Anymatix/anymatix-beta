Anymatix Beta
=============


**Windows:** [anymatix-1.0.0-beta.7.3-setup.exe](https://github.com/Anymatix/anymatix-beta/releases/download/v1.0.0-beta.7.3/anymatix-1.0.0-beta.7.3-setup.exe)

and run anyway when prompted by Windows SmartScreen, or read below if it does not start (because SmartScreen blocks it).

Anymatix beta releases are unsigned, so you need to follow special instructions. Manual download is anyway possible (see below).

Windows
-------


Or open PowerShell (Start menu > PowerShell) and paste:
```
curl.exe -L --progress-bar "https://github.com/Anymatix/anymatix-beta/releases/download/v1.0.0-beta.7.3/anymatix-1.0.0-beta.7.3-setup.exe" -o "anymatix-1.0.0-beta.7.3-setup.exe"; Unblock-File "anymatix-1.0.0-beta.7.3-setup.exe"; .\anymatix-1.0.0-beta.7.3-setup.exe
```

macOS
-----
Open Terminal and paste:
```
curl -LOC- https://github.com/Anymatix/anymatix-beta/releases/download/v1.0.0-beta.7.3/anymatix-1.0.0-beta.7.3.dmg && xattr -d com.apple.quarantine anymatix-1.0.0-beta.7.3.dmg 2>/dev/null || true && open anymatix-1.0.0-beta.7.3.dmg
```

Longer explanation
------------------
These beta releases are unsigned, so your system will show security warnings. Windows requires PowerShell's Unblock-File to remove download restrictions. macOS requires a script to remove quarantine flags. The one-liners above handle this automatically.

Manual download
---------------
If you prefer to download manually:

**Windows:** [anymatix-1.0.0-beta.7.3-setup.exe](https://github.com/Anymatix/anymatix-beta/releases/download/v1.0.0-beta.7.3/anymatix-1.0.0-beta.7.3-setup.exe)

**macOS:** [anymatix-1.0.0-beta.7.3.dmg](https://github.com/Anymatix/anymatix-beta/releases/download/v1.0.0-beta.7.3/anymatix-1.0.0-beta.7.3.dmg)

After manual download, Windows users should run PowerShell as administrator and use `Unblock-File` on the downloaded file before running it. macOS users should run `xattr -d com.apple.quarantine anymatix-1.0.0-beta.7.3.dmg` to remove quarantine flags before opening the DMG.
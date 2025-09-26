Anymatix Beta
=============

Windows
-------
Open PowerShell (Start menu > PowerShell) and paste:
```
curl.exe -L --progress-bar "https://github.com/Anymatix/anymatix-beta/releases/download/v{{VERSION}}/anymatix-{{VERSION}}-setup.exe" -o "anymatix-setup.exe"; Unblock-File "anymatix-setup.exe"; .\anymatix-setup.exe
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
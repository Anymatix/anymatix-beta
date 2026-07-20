Anymatix Beta
=============


**Windows (untested):** [anymatix-1.0.0-beta.8.1-setup.exe](https://github.com/Anymatix/anymatix-beta/releases/download/v1.0.0-beta.8.1/anymatix-1.0.0-beta.8.1-setup.exe)

and run anyway when prompted by Windows SmartScreen, or read below if it does not start (because SmartScreen blocks it).

**macOS:** [anymatix-1.0.0-beta.8.1.dmg](https://github.com/Anymatix/anymatix-beta/releases/download/v1.0.0-beta.8.1/anymatix-1.0.0-beta.8.1.dmg)

and open anyway when prompted by macOS Gatekeeper, or read below if it does not open (because Gatekeeper blocks it).

**Linux (untested):** [anymatix-1.0.0-beta.8.1.AppImage](https://github.com/Anymatix/anymatix-beta/releases/download/v1.0.0-beta.8.1/anymatix-1.0.0-beta.8.1.AppImage) · [anymatix-1.0.0-beta.8.1.deb](https://github.com/Anymatix/anymatix-beta/releases/download/v1.0.0-beta.8.1/anymatix-1.0.0-beta.8.1.deb)

Windows and Linux builds are **untested**. Please report problems on this repository:
https://github.com/Anymatix/anymatix-beta/issues

Anymatix beta releases are unsigned, so you need to follow special instructions. Manual download is anyway possible (see below).

Windows
-------


Or open PowerShell (Start menu > PowerShell) and paste:
```
curl.exe -L --progress-bar "https://github.com/Anymatix/anymatix-beta/releases/download/v1.0.0-beta.8.1/anymatix-1.0.0-beta.8.1-setup.exe" -o "anymatix-1.0.0-beta.8.1-setup.exe"; Unblock-File "anymatix-1.0.0-beta.8.1-setup.exe"; .\anymatix-1.0.0-beta.8.1-setup.exe
```

macOS
-----
Open Terminal and paste:
```
curl -LOC- https://github.com/Anymatix/anymatix-beta/releases/download/v1.0.0-beta.8.1/anymatix-1.0.0-beta.8.1.dmg && xattr -d com.apple.quarantine anymatix-1.0.0-beta.8.1.dmg 2>/dev/null || true && open anymatix-1.0.0-beta.8.1.dmg
```

Linux
-----
Download the AppImage, mark it executable, and run:
```
curl -LOC- https://github.com/Anymatix/anymatix-beta/releases/download/v1.0.0-beta.8.1/anymatix-1.0.0-beta.8.1.AppImage && chmod +x anymatix-1.0.0-beta.8.1.AppImage && ./anymatix-1.0.0-beta.8.1.AppImage
```

Or install the `.deb` on Debian/Ubuntu-based systems.

Longer explanation
------------------
These beta releases are unsigned, so your system will show security warnings. Windows requires PowerShell's Unblock-File to remove download restrictions. macOS requires a script to remove quarantine flags. The one-liners above handle this automatically.

Manual download
---------------
If you prefer to download manually:

**Windows (untested):** [anymatix-1.0.0-beta.8.1-setup.exe](https://github.com/Anymatix/anymatix-beta/releases/download/v1.0.0-beta.8.1/anymatix-1.0.0-beta.8.1-setup.exe)

**macOS:** [anymatix-1.0.0-beta.8.1.dmg](https://github.com/Anymatix/anymatix-beta/releases/download/v1.0.0-beta.8.1/anymatix-1.0.0-beta.8.1.dmg)

**Linux (untested):** [anymatix-1.0.0-beta.8.1.AppImage](https://github.com/Anymatix/anymatix-beta/releases/download/v1.0.0-beta.8.1/anymatix-1.0.0-beta.8.1.AppImage) · [anymatix-1.0.0-beta.8.1.deb](https://github.com/Anymatix/anymatix-beta/releases/download/v1.0.0-beta.8.1/anymatix-1.0.0-beta.8.1.deb)

After manual download, Windows users should run PowerShell as administrator and use `Unblock-File` on the downloaded file before running it. macOS users should run `xattr -d com.apple.quarantine anymatix-1.0.0-beta.8.1.dmg` to remove quarantine flags before opening the DMG.

Issues
------
Report bugs against the public binaries here: https://github.com/Anymatix/anymatix-beta/issues

Anymatix Beta
=============

Windows
-------
Open PowerShell (Start menu > PowerShell) and paste:
```
curl -L https://github.com/Anymatix/anymatix-beta/releases/download/v1.0.0-beta.7/anymatix-1.0.0-beta.7-setup.exe && Unblock-File anymatix-1.0.0-beta.7-setup.exe && .\anymatix-1.0.0-beta.7-setup.exe
```

macOS
-----
Open Terminal and paste:
```
curl -L https://github.com/Anymatix/anymatix-beta/releases/download/v1.0.0-beta.7/anymatix-1.0.0-beta.7-bundle.zip && unzip -o anymatix-1.0.0-beta.7-bundle.zip && bash ./install.sh
```

Longer explanation
------------------
These beta releases are unsigned, so your system will show security warnings. Windows requires PowerShell's Unblock-File to remove download restrictions. macOS requires a script to remove quarantine flags. The one-liners above handle this automatically.

Manual download
---------------
If you prefer to download manually:

**Windows:** [anymatix-1.0.0-beta.7-setup.exe](https://github.com/Anymatix/anymatix-beta/releases/download/v1.0.0-beta.7/anymatix-1.0.0-beta.7-setup.exe)

**macOS:** [anymatix-1.0.0-beta.7-bundle.zip](https://github.com/Anymatix/anymatix-beta/releases/download/v1.0.0-beta.7/anymatix-1.0.0-beta.7-bundle.zip)

After manual download, Windows users should run PowerShell as administrator and use `Unblock-File` on the downloaded file before running it. macOS users should extract the bundle and run the included install script.
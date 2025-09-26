Anymatix Beta
=============

Windows
-------
Open PowerShell (Start menu > PowerShell) and paste:
```
curl -LO https://github.com/Anymatix/anymatix-beta/releases/download/v{{VERSION}}/anymatix-{{VERSION}}-setup.exe && Unblock-File anymatix-{{VERSION}}-setup.exe && .\anymatix-{{VERSION}}-setup.exe
```

macOS
-----
Open Terminal and paste:
```
curl -LO https://github.com/Anymatix/anymatix-beta/releases/download/v{{VERSION}}/anymatix-{{VERSION}}-bundle.zip && unzip -o anymatix-{{VERSION}}-bundle.zip && bash ./install.sh
```

Longer explanation
------------------
These beta releases are unsigned, so your system will show security warnings. Windows requires PowerShell's Unblock-File to remove download restrictions. macOS requires a script to remove quarantine flags. The one-liners above handle this automatically.

Manual download
---------------
If you prefer to download manually:

**Windows:** [anymatix-{{VERSION}}-setup.exe](https://github.com/Anymatix/anymatix-beta/releases/download/v{{VERSION}}/anymatix-{{VERSION}}-setup.exe)

**macOS:** [anymatix-{{VERSION}}-bundle.zip](https://github.com/Anymatix/anymatix-beta/releases/download/v{{VERSION}}/anymatix-{{VERSION}}-bundle.zip)

After manual download, Windows users should run PowerShell as administrator and use `Unblock-File` on the downloaded file before running it. macOS users should extract the bundle and run the included install script.
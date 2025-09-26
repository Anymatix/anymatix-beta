Anymatix Beta
=============

Windows
-------
Open PowerShell (Start menu > PowerShell) and paste:
```
curl -L -o anymatix-setup.exe https://github.com/Anymatix/anymatix-beta/releases/download/v{{VERSION}}/anymatix-{{VERSION}}-setup.exe && Unblock-File anymatix-setup.exe && .\anymatix-setup.exe
```

macOS
-----
Open Terminal and paste:
```
curl -L -o anymatix-bundle.zip https://github.com/Anymatix/anymatix-beta/releases/download/v{{VERSION}}/anymatix-{{VERSION}}-bundle.zip && unzip -o anymatix-bundle.zip && bash ./install.sh
```

Longer explanation
------------------
These beta releases are unsigned, so your system will show security warnings. Windows requires PowerShell's Unblock-File to remove download restrictions. macOS requires a script to remove quarantine flags. The one-liners above handle this automatically.
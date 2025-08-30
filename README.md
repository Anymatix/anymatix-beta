Anymatix Beta
=============

Windows
-------
Download the setup executable from:
https://github.com/Anymatix/anymatix-beta/releases/download/v1.0.0-beta.5/anymatix-1.0.0-beta.5-setup.exe

Install (2 steps):
1. Run the EXE
2. If SmartScreen warns, More info -> Run anyway (first time only)

macOS (Apple Silicon)
---------------------

The app is not signed yet, so we need to use a script to remove the quarantine flag. You can do this yourself if you know how, but we distribute  a zip containing a script that does it. Here are the super-simplified instructions.

**SIMPLE INSTRUCTIONS (DO NOT OPEN THE ZIP AFTER DOWNOAD, OPEN TERMINAL AND COPY PASTE)**


1. Click to download. **Do not open after download**:

	https://github.com/Anymatix/anymatix-beta/releases/download/v1.0.0-beta.5/anymatix-1.0.0-beta.5-bundle.zip


2. **Open terminal and copy paste** (replace "Downloads" if you downloaded it in a different directory):
	```
	cd ~/Downloads && unzip -o anymatix-1.0.0-beta.5-bundle.zip && bash ./install.sh
	```
 
3. When the DMG opens, drag Anymatix to Applications (first launch: right‑click > Open if Gatekeeper warns).

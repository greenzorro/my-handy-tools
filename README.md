# my-handy-tools

Automated software deployment toolkit for Windows (winget) and macOS (Homebrew). Manages app lists, generates docs, and provides smart package control.

For Windows users: Press Win+R, type "powershell", then copy-paste commands of chosen apps to install.

For Mac users: Press Command+Space, type "Terminal", hit Enter, paste this command in Terminal to install Homebrew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`, then copy-paste commands of chosen apps to install.

For advanced users: Fork this repo, consult AI about notes.md to understand advanced scripts.

## Windows

### OS Enhancements

**DiskGenius**

Disk management and recovery tool.

```powershell
winget install Eassos.DiskGenius
```

**BleachBit**

Disk cleaning tool.

```powershell
winget install BleachBit.BleachBit
```

**Clash Verge Rev**

Proxy Client.

```powershell
winget install ClashVergeRev.ClashVergeRev
```

**QuickLook**

File preview by pressing spacebar, bringing macOS QuickLook functionality to Windows.

```powershell
winget install QL-Win.QuickLook
```

**Everything**

File search tool.

```powershell
winget install voidtools.Everything
```

**Ueli**

Launcher that requires some habit change, but becomes a productivity powerhouse once accustomed.

```powershell
winget install OliverSchwendener.ueli
```

### File & Software Management

**Geek Uninstaller**

Uninstaller and cleanup tool.

```powershell
winget install GeekUninstaller.GeekUninstaller
```

**Google Drive**

Cloud drive and sync tool.

```powershell
winget install Google.GoogleDrive
```

**Resilio Sync**

P2P sync tool, no cloud storage.

> Manual install: [https://www.resilio.com/sync/](https://www.resilio.com/sync/)

**Odrive sync**

Unified cloud storage sync tool that connects to Google Drive/OneDrive/Dropbox, bypassing network and client restrictions.

> Manual install: [https://www.odrive.com/](https://www.odrive.com/)

**7-Zip**

File compression and extraction tool.

```powershell
winget install 7zip.7zip
```

**Bulk Rename Utility**

Powerful rename tool that can handle almost any batch renaming requirement.

```powershell
winget install TGRMNSoftware.BulkRenameUtility
```

**Free Download Manager**

Download manager tool.

```powershell
winget install SoftDeluxe.FreeDownloadManager
```

**IPFS Desktop**

Decentralized storage.

```powershell
winget install IPFS.IPFS-Desktop
```

### Daily Use

**Google Chrome**

Browser.

```powershell
winget install Google.Chrome.EXE
```

**Obsidian**

Notes and personal library.

```powershell
winget install Obsidian.Obsidian
```

**Zhipu GLM Voice Input**

AI Voice Input

```powershell
winget install ZhipuAI.AutoGLM
```

**Kuaitie**

Clipboard sync tool with mobile device support.

> Manual install: [https://kuaitie.cloud/](https://kuaitie.cloud/)

**ShareX**

Screenshot and screen recording tool with extensive shortcuts, supports scrolling capture, local highlighting, step annotation. Includes utilities: image stitching, splitting, adding borders to screenshots.

```powershell
winget install ShareX.ShareX
```

**Baimiao**

Screenshot OCR tool with high accuracy for Chinese text recognition.

```powershell
winget install Uzero.ScanScan
```

**VLC Media Player**

Local multimedia player supporting a wide range of formats.

```powershell
winget install VideoLAN.VLC
```

**Calibre**

E-book management tool.

```powershell
winget install calibre.calibre
```

**Eudic Dictionary**

Dictionary software.

```powershell
winget install EuSoft.Eudic
```

**WeChat**

Dominant Chinese IM.

```powershell
winget install Tencent.WeChat
```

**QQ Music**

Rich music library.

```powershell
winget install Tencent.QQMusic
```

**NetEase Cloud Music**

Supplementary music library.

```powershell
winget install NetEase.CloudMusic
```

### Production Tools

**VS Code**

Popular IDE.

```powershell
winget install Microsoft.VisualStudioCode
```

**Xmind**

Mind Map.

```powershell
winget install Xmind.Xmind
```

**Figma**

UI Design.

```powershell
winget install Figma.Figma
```

**GIMP 3.0**

Lightweight image processing, free alternative to Photoshop. Complete basic features, fast startup, convenient for quick tasks like resizing. Can change tool shortcuts to Photoshop style.

```powershell
winget install GIMP.GIMP.3
```

**Inkscape**

Vector graphics tool, free alternative to Illustrator. Opens .ai files with good fidelity, sufficient for downloading assets and saving as images.

```powershell
winget install Inkscape.Inkscape
```

**Caesium**

Image compression tool.

```powershell
winget install SaeraSoft.CaesiumImageCompressor
```

**Collagelt**

Collage tool for quickly creating photo walls and mood boards. Free version has watermark.

> Manual install: [https://www.collageitfree.com/](https://www.collageitfree.com/)

**HandBrake**

Large video compression for easy transfer. Also converts videos from other formats to MP4.

```powershell
winget install HandBrake.HandBrake
```


## Mac

### OS Enhancements

**Cleaner One Pro**

Disk cleaning tool.

```bash
mas install 1133028347
```

**dozer**

Menu bar icon management tool that hides infrequently used icons.

> Manual install: [https://github.com/Mortennn/Dozer](https://github.com/Mortennn/Dozer)

**hyperswitch**

Task switcher more flexible and accurate than macOS built-in switching.

> Manual install: [https://bahoom.com/hyperswitch](https://bahoom.com/hyperswitch)

**raycast**

Launcher that requires some habit change, but becomes a productivity powerhouse once accustomed.

```bash
brew install --cask raycast
```

**clash-verge-rev**

Proxy Client.

```bash
brew install --cask clash-verge-rev
```

### File & Software Management

**appcleaner**

Uninstaller and cleanup tool.

```bash
brew install --cask appcleaner
```

**google-drive**

Cloud drive and sync tool.

```bash
brew install --cask google-drive
```

**resilio-sync**

P2P sync tool, no cloud storage.

```bash
brew install --cask resilio-sync
```

**odrive**

Unified cloud storage sync tool that connects to Google Drive/OneDrive/Dropbox, bypassing network and client restrictions.

```bash
brew install --cask odrive
```

**free-download-manager**

Download manager tool.

```bash
brew install --cask free-download-manager
```

### Daily Use

**google-chrome**

Browser.

```bash
brew install --cask google-chrome
```

**obsidian**

Notes and personal library.

```bash
brew install --cask obsidian
```

**Zhipu GLM Input**

AI Voice Input.

> Manual install: [https://autoglm.zhipuai.cn/autotyper/](https://autoglm.zhipuai.cn/autotyper/)

**kuaitie**

Clipboard sync tool with mobile device support.

```bash
brew install --cask kuaitie
```

**Xnip**

Screenshot tool supporting scrolling capture, local highlighting, step annotation.

```bash
mas install 1221250572
```

**baimiao**

Screenshot OCR tool with high accuracy for Chinese text recognition.

> Manual install: [https://baimiao.uzero.cn/](https://baimiao.uzero.cn/)

**screen-studio**

Screen recording tool with mouse following and automatic camera zooming.

```bash
brew install --cask screen-studio
```

**vlc**

Local multimedia player supporting a wide range of formats.

```bash
brew install --cask vlc
```

**calibre**

E-book management tool.

```bash
brew install --cask calibre
```

**eudic**

Dictionary software.

```bash
brew install --cask eudic
```

**wechat**

Dominant Chinese IM.

```bash
brew install --cask wechat
```

**qqmusic**

Rich music library.

```bash
brew install --cask qqmusic
```

**neteasemusic**

Supplementary music library.

```bash
brew install --cask neteasemusic
```

**Friendly Streaming**

borderless, shadowless - you can imagine what it's used for

```bash
mas install 553245401
```

### Production Tools

**visual-studio-code**

Popular IDE.

```bash
brew install --cask visual-studio-code
```

**xmind**

Mind Map.

```bash
brew install --cask xmind
```

**figma**

UI Design.

```bash
brew install --cask figma
```

**gimp**

Lightweight image processing, free alternative to Photoshop. Complete basic features, fast startup, convenient for quick tasks like resizing. Can change tool shortcuts to Photoshop style.

```bash
brew install --cask gimp
```

**inkscape**

Vector graphics tool, free alternative to Illustrator. Opens .ai files with good fidelity, sufficient for downloading assets and saving as images.

```bash
brew install --cask inkscape
```

**caesium**

Image compression tool.

> Manual install: [https://saerasoft.com/caesium/](https://saerasoft.com/caesium/)

**CollageIt 3 Free**

Collage tool for quickly creating photo walls and mood boards. Free version has watermark.

> Manual install: [https://www.collageitfree.com/](https://www.collageitfree.com/)

**handbrake**

Large video compression for easy transfer. Also converts videos from other formats to MP4.

```bash
brew install --cask handbrake
```


---

Created by [Victor_42](https://victor42.work/)

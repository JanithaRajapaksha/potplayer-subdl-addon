# SubDL Subtitle Management Add-on for Daum PotPlayer

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows-0078D6.svg)](https://microsoft.com/windows)
[![PotPlayer Compatible](https://img.shields.io/badge/PotPlayer-v20%2B-orange.svg)](https://potplayer.daum.net/)

An enhanced, high-performance subtitle search, download, and auto-loading extension for **Daum PotPlayer**, powered by the official **[SubDL API](https://subdl.com/)**.

---

## 🌟 Key Features

* **Official SubDL API v1 Integration**: Directly connects to SubDL's extensive subtitle database for movies and TV shows.
* **Intelligent Media Filename Extraction**:
  * Automatically detects scene release names, resolution (`2160p`, `1080p`, `720p`), source (`BluRay`, `WEB-DL`, `HDTV`), and release groups (`SPARKS`, `RARBG`, `YTS`, etc.).
  * Extracts TV show Season and Episode markers (`S01E05` and `1x05`).
  * Extracts release years (`1920–2099`) and cleans sanitized titles.
* **Release Match Scoring & Smart Ranking**:
  * Calculates a 0–100% match score against the active video file.
  * Displays match badges (e.g. `[Match 90%]`) and sorts highest-fidelity tracks to the top.
* **Zero Playback Interruption**:
  * Subtitles download and load **instantly into the active video stream** without stopping, buffering, or restarting playback.
* **Server-Side & Client-Side Archive Handling**:
  * Employs SubDL's `unpack=1` parameter to fetch direct, uncompressed `.srt` and `.ass` files.
  * Includes a built-in decompression fallback (`HostDecompress`) for ZIP archives (`PK` headers).
* **Multi-Language Support**:
  * Supports 40+ languages including English, Spanish, Arabic, French, German, Portuguese, Russian, Chinese, Japanese, Korean, Hindi, and more.
* **PotPlayer Automation Compatible**:
  * Works out-of-the-box with PotPlayer's built-in *"Auto search for subtitles when opening a file"* and *"Auto download best match"*.
* **Zero Bloat & Zero Background Daemons**:
  * Pure native AngelScript (`.as`) implementation. Uses **0 MB additional RAM** and requires no background processes or heavy third-party runtimes.

---

## 🚀 Quick Installation

### Option 1: One-Click Installer (Recommended)
1. Close **PotPlayer**.
2. Right-click `install.bat` and select **Run as Administrator** (or run `install.ps1` in PowerShell).
3. The installer will automatically:
   * Detect your PotPlayer installation (`64-bit` or `32-bit`).
   * Create a backup of any existing SubDL script (`.bak`).
   * Install the enhanced `SubtitleSearch - SubDL.as` and `SubtitleSearch - SubDL.ico`.

### Option 2: Manual Installation
1. Locate your PotPlayer installation directory:
   * **64-bit (Standard)**: `C:\Program Files\DAUM\PotPlayer\`
   * **32-bit**: `C:\Program Files (x86)\DAUM\PotPlayer\`
2. Navigate to the subtitle search extension folder:
   ```text
   PotPlayer\Extension\Subtitle\Search\
   ```
3. Copy `SubtitleSearch - SubDL.as` and `SubtitleSearch - SubDL.ico` into this directory.

---

## 🔑 SubDL API Key Configuration

SubDL requires an API key for search requests:

1. Create a free account at [subdl.com](https://subdl.com/).
2. Navigate to your user profile panel: [subdl.com/panel](https://subdl.com/panel).
3. Copy your personal **API Key**.
4. Open **PotPlayer**:
   * Press <kbd>F5</kbd> to open **Preferences**.
   * In the left tree, navigate to: **Extensions** ➔ **Subtitle Search**.
   * Highlight **SubDL** in the extension list.
   * Click **Account / Configure** (or **Modify**).
   * Paste your API Key and click **OK**.

---

## 🎬 How to Use

### 1. Manual Search During Playback
1. Play any movie or TV episode in PotPlayer.
2. Press <kbd>Alt</kbd> + <kbd>S</kbd> (or right-click ➔ **Subtitles** ➔ **Subtitle Searching** ➔ **Search Subtitles**).
3. PotPlayer will automatically query SubDL using the video's parsed title and metadata.
4. Select your preferred subtitle track and click **Load** (or double-click).
5. The subtitle will immediately appear on screen!

### 2. Fully Automated Subtitle Downloading
To have PotPlayer automatically find and load subtitles whenever you open a video:
1. Open PotPlayer Preferences (<kbd>F5</kbd>).
2. Go to **Subtitles** ➔ **Subtitle Searching**.
3. Enable:
   * `[x] Auto search for subtitles online if there are no subtitles`
   * `[x] Auto download the first matched subtitle` (or `Show search result window`)
4. Under **Preferred Languages**, check your desired languages (e.g. `English`, `Spanish`).

### 3. Keyboard Shortcuts
| Hotkey | Action |
| :--- | :--- |
| <kbd>Alt</kbd> + <kbd>S</kbd> | Open Online Subtitle Search window |
| <kbd>Alt</kbd> + <kbd>O</kbd> | Subtitle Search Options |
| <kbd>[</kbd> | Delay subtitle by 0.5s |
| <kbd>]</kbd> | Advance subtitle by 0.5s |
| <kbd>/</kbd> | Reset subtitle sync to 0.0s |

---

## 🏗️ Technical Architecture

```
[PotPlayer Core Engine]
       │
       ▼ (Passes MovieFileName & Metadata)
[SubtitleSearch - SubDL.as]
       │
       ├──► 1. ParseMediaMetadata() ──► Clean Title, Year, S##E##, Scene Tags
       │
       ├──► 2. SubDL API GET Request ─► https://api.subdl.com/api/v1/subtitles?unpack=1
       │
       ├──► 3. JsonReader Parser ─────► Extracts unpack_files with direct SRT URLs
       │
       ├──► 4. ComputeMatchScore() ───► Scene tags match calculation (0-100%)
       │
       ▼ (Returns array<dictionary> to PotPlayer UI)
[PotPlayer Search Dialog (Alt+S)]
       │
       ▼ (User or Auto-Download picks subtitle track)
[SubtitleDownload(url)]
       │
       ├──► Direct download from https://dl.subdl.com/...
       ├──► HostDecompress() fallback if ZIP archive detected
       ▼
[In-Stream Injection & Subtitle Rendering]
```

### Why Previous SubDL Scripts Failed:
1. **Unparsed Filenames**: Older scripts passed raw file paths (e.g., `D:\Movies\Dune.mkv`) directly into the `film_name` parameter, breaking query resolution.
2. **Binary ZIP Corruption**: Older scripts called SubDL without `unpack=1`, receiving binary `.zip` packages and passing raw binary data into PotPlayer's text rendering engine.
3. **No Scene Scoring**: Results were not scored, causing auto-download to grab mismatched frame rates or foreign releases.

This enhanced add-on solves all three issues cleanly within PotPlayer's native AngelScript engine.

---

## 🗑️ Uninstallation

* Run `uninstall.bat` (or execute `uninstall.ps1` in PowerShell).
* If a backup of the original script (`SubtitleSearch - SubDL.as.bak`) was created during installation, the uninstaller will automatically restore it.

---

## 📄 License & Credits

* Developed for the PotPlayer community.
* Subtitle database powered by [SubDL](https://subdl.com/).

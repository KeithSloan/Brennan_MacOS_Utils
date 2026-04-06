# Brennan MacOS Utils

Utilities for managing and transferring music on macOS, specifically for the **Brennan B3+** music player and **Sonos** speakers.

---

## Process Qobuz FLAC for Brennan

Downloads from [Qobuz](https://www.qobuz.com) embed artwork inside FLAC files. This causes playback problems on the Brennan B3+ and Sonos. This utility strips the embedded artwork losslessly (audio and all metadata tags are fully preserved) and writes the processed files to `~/Music/BrennanMusic/Transfer/` ready for copying to a NAS or directly to the Brennan.

### Requirements

- macOS (tested on macOS 26.1)
- [Homebrew](https://brew.sh) with `ffmpeg` installed:
  ```bash
  brew install ffmpeg
  ```

### Directory structure

Qobuz downloads are expected to follow this structure (standard Qobuz layout):

```
QoBuz_Digital/
  Artists/
    Artist Name/
      Album Name/
        01 - Track.flac
        02 - Track.flac
        ...
```

Processed files are written to:

```
~/Music/BrennanMusic/Transfer/
  Artists/
    Artist Name/
      Album Name/
        01 - Track.flac   ← artwork stripped, audio identical
        ...
```

The transfer directory is **cleared on each run** so it always contains only the most recently processed batch.

---

## Installation

### 1. Install ffmpeg

```bash
brew install ffmpeg
```

### 2. Clone this repo

```bash
git clone https://github.com/ksloan/Brennan_MacOS_Utils.git ~/github/Brennan_MacOS_Utils
```

### 3. Install the BrennanTransfer app

```bash
bash ~/github/Brennan_MacOS_Utils/install_automator_app.sh
```

This compiles `automator/ProcessQobuzFLAC.applescript` into `/Applications/BrennanTransfer.app`.

---

## Usage

### Double-click BrennanTransfer

1. Double-click **BrennanTransfer** in `/Applications`
2. A folder picker opens at `~/Music` — single-click your Qobuz folder (e.g. `QoBuz_Digital`) then press **Return**
3. A macOS notification fires when processing begins
4. A completion dialog reports how many files were processed
5. Processed files are in `~/Music/BrennanMusic/Transfer/`

### Drag and drop

Drag any folder containing FLAC files onto the **BrennanTransfer** app icon — processing starts immediately with no dialog.

### Command line

```bash
bash ~/github/Brennan_MacOS_Utils/scripts/process_qobuz_flac.sh ~/Music/QoBuz_Digital
```

---

## Files

| File | Purpose |
|------|---------|
| `scripts/process_qobuz_flac.sh` | Core processing script — strips artwork, writes to Transfer dir |
| `automator/ProcessQobuzFLAC.applescript` | AppleScript source for the BrennanTransfer app |
| `install_automator_app.sh` | Compiles and installs BrennanTransfer.app to `/Applications` |

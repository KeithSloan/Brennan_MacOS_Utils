# Brennan MacOS Utils

Utilities for managing and transferring music on macOS, specifically for the **Brennan B3+** music player and **Sonos** speakers.

---

## Process Qobuz FLAC for Brennan

Downloads from [Qobuz](https://www.qobuz.com) embed artwork inside FLAC files, and hi-res tracks may be at sample rates (e.g. 88.2 kHz, 96 kHz, 192 kHz) that the Brennan B3+ and Sonos cannot play. This utility:

- **Strips embedded artwork** losslessly (audio and all metadata tags are fully preserved)
- **Downsamples to 48 kHz** any file with a sample rate above 48 kHz (files at 44.1 kHz or 48 kHz are copied unchanged)

Processed files are written to `~/Music/BrennanMusic/Transfer/` ready for copying to a NAS or directly to the Brennan. A log of all artwork removals and resampling operations is written to `~/Music/BrennanMusic/process_qobuz_flac.log`.

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
  Artist Name/
    Album Name/
      01 - Track.flac   ← artwork stripped, downsampled if needed
      ...
```

This matches the directory structure expected by the Brennan B3+ Web UI bulk upload.

The transfer directory is **cleared on each run** so it always contains only the most recently processed batch.

A log is written to `~/Music/BrennanMusic/process_qobuz_flac.log` listing every file where artwork was removed or resampling occurred, plus a summary count. Example:

```
Process Qobuz FLAC — 2026-04-07 14:32:01
Source: /Users/you/Music/QoBuz_Digital
---
  [artwork removed] Artist/Album/01 - Track.flac
  [artwork removed, resampled 96000Hz → 48000Hz] Artist/Album/02 - Track.flac
  [resampled 192000Hz → 48000Hz] Artist/Album/03 - Track.flac
---
Processed : 12
Artwork removed : 8
Resampled : 3
Completed : 2026-04-07 14:32:45
```

---

## Release Sonos Session

When Spotify is active on a Sonos speaker via the iPhone app, it holds a Spotify Connect session that blocks the Brennan Web UI from taking control. This utility stops playback on the **Family Room** Sonos Five, releasing the session so the Brennan Web UI can take over.

### Requirements

- Python 3 with [SoCo](https://github.com/SoCo/SoCo):
  ```bash
  pip3 install soco
  ```

### Usage

#### Double-click ReleaseSonosSession

Double-click **ReleaseSonosSession** in `/Applications`. A notification confirms the speaker is released.

#### Command line

```bash
bash ~/github/Brennan_MacOS_Utils/scripts/release_sonos_session.sh
```

---

## Installation

### 1. Install Homebrew (if not already installed)

[Homebrew](https://brew.sh) is a macOS package manager. If you don't have it:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Verify it's working:

```bash
brew --version
```

### 2. Install ffmpeg

Required by the Qobuz FLAC processor:

```bash
brew install ffmpeg
```

### 3. Install Python 3 (if not already installed)

macOS includes Python 3, but if needed:

```bash
brew install python
```

Verify:

```bash
python3 --version
```

### 4. Install SoCo

[SoCo](https://github.com/SoCo/SoCo) is a Python library for controlling Sonos speakers. Required by the Release Sonos Session utility:

```bash
pip3 install soco
```

Verify:

```bash
python3 -c "import soco; print('SoCo OK')"
```

### 5. Clone this repo

```bash
git clone https://github.com/KeithSloan/Brennan_MacOS_Utils.git ~/github/Brennan_MacOS_Utils
```

### 6. Install the macOS apps

```bash
bash ~/github/Brennan_MacOS_Utils/install_automator_app.sh
```

This compiles both AppleScripts and installs them to `/Applications`:
- **BrennanTransfer.app** — process Qobuz FLAC files for Brennan/Sonos
- **ReleaseSonosSession.app** — release Spotify Connect on the Family Room Sonos

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
| `scripts/process_qobuz_flac.sh` | Core processing script — strips artwork, downsamples if >48 kHz, writes log |
| `scripts/release_sonos_session.sh` | Stops playback on Family Room Sonos to release Spotify Connect session |
| `automator/ProcessQobuzFLAC.applescript` | AppleScript source for the BrennanTransfer app |
| `automator/ReleaseSonosSession.applescript` | AppleScript source for the ReleaseSonosSession app |
| `install_automator_app.sh` | Compiles and installs both apps to `/Applications` |

# Brennan MacOS Utils

macOS utilities for managing and transferring music between [Qobuz](https://www.qobuz.com), the **Brennan B3+** music player, and **Sonos** speakers.

| App | Script | Purpose |
|-----|--------|---------|
| `BrennanTransfer.app` | `process_qobuz_flac.sh` | Strip artwork & downsample Qobuz FLAC files ready for Brennan/Sonos |
| `ReleaseSonosSession.app` | `release_sonos_session.sh` | Release a Spotify Connect session so the Brennan Web UI can take control |
| `ListBrennanNAS.app` | `list_brennan_nas.sh` | List all artists, albums and track counts on the Brennan B3+ NAS |

---

## Typical workflow

1. Download album from Qobuz → run **BrennanTransfer** → processed files land in `~/Music/BrennanMusic/Transfer/`
2. Upload via the Brennan B3+ Web UI bulk upload (or copy to NAS directly)
3. If Spotify is playing on a Sonos speaker and the Brennan Web UI can't take control → run **ReleaseSonosSession**
4. To verify what is on the B3+ NAS → run **ListBrennanNAS**

---

## Process Qobuz FLAC for Brennan

Downloads from [Qobuz](https://www.qobuz.com) embed artwork inside FLAC files, and hi-res tracks may use sample rates (e.g. 88.2 kHz, 96 kHz, 192 kHz) that the Brennan B3+ and Sonos cannot play. This utility:

- **Strips embedded artwork** losslessly — audio and all metadata tags are fully preserved
- **Downsamples to 48 kHz** any track with a sample rate above 48 kHz — files at 44.1 kHz or 48 kHz are copied unchanged

Processed files are written to `~/Music/BrennanMusic/Transfer/` ready for upload via the Brennan Web UI or copying directly to the B3+. A log of all changes is written to `~/Music/BrennanMusic/process_qobuz_flac.log`.

### Requirements

- macOS (tested on macOS 26.1)
- [Homebrew](https://brew.sh) with `ffmpeg`:
  ```bash
  brew install ffmpeg
  ```

### Directory structure

Qobuz downloads follow this standard layout:

```
QoBuz_Digital/
  Artists/
    Artist Name/
      Album Name/
        01 - Track.flac
        02 - Track.flac
        ...
```

Processed files are written as:

```
~/Music/BrennanMusic/Transfer/
  Artist Name/
    Album Name/
      01 - Track.flac   ← artwork stripped, downsampled if needed
      ...
```

This matches the directory structure expected by the **Brennan B3+ Web UI bulk upload**.

The transfer directory is **cleared on each run** so it always contains only the most recently processed batch.

### Usage

**Double-click BrennanTransfer:**
1. Double-click **BrennanTransfer** in `/Applications`
2. A folder picker opens at `~/Music` — select your Qobuz folder (e.g. `QoBuz_Digital`) and press **Return**
3. A macOS notification fires when processing begins
4. A completion dialog reports how many files were processed
5. Processed files are in `~/Music/BrennanMusic/Transfer/`

**Drag and drop:** drag any folder containing FLAC files onto the **BrennanTransfer** icon — processing starts immediately.

**Command line:**
```bash
bash ~/github/Brennan_MacOS_Utils/scripts/process_qobuz_flac.sh ~/Music/QoBuz_Digital
```

### Log example

```
Process Qobuz FLAC — 2026-04-07 14:32:01
Source: /Users/you/Music/QoBuz_Digital
---
  [artwork removed] Artist/Album/01 - Track.flac
  [artwork removed, resampled 96000Hz → 48000Hz] Artist/Album/02 - Track.flac
  [resampled 192000Hz → 48000Hz] Artist/Album/03 - Track.flac
---
Processed      : 12
Artwork removed: 8
Resampled      : 3
Completed      : 2026-04-07 14:32:45
```

---

## Release Sonos Session

When Spotify is active on a Sonos speaker via the iPhone app, it holds a Spotify Connect session that blocks the Brennan Web UI from taking control. This utility discovers all Sonos speakers on the network, prompts you to pick one, then stops playback to release the session.

### Requirements

- Python 3 with [SoCo](https://github.com/SoCo/SoCo):
  ```bash
  pip3 install soco
  ```

### Usage

**Double-click ReleaseSonosSession:**
1. Double-click **ReleaseSonosSession** in `/Applications`
2. A list of discovered Sonos speakers appears — select one and click OK
3. A notification confirms the speaker is released — the Brennan Web UI can now take control

**Command line:**
```bash
bash ~/github/Brennan_MacOS_Utils/scripts/release_sonos_session.sh
```

---

## List Brennan NAS Contents

Mounts the Brennan B3+ NAS share over SMB, lists all artists and albums with per-album track counts, saves a report to `~/Music/BrennanMusic/nas_contents.txt`, and opens it in TextEdit.

Useful for verifying what is on the B3+ before or after uploading music, or when setting up the B3+ as a Sonos Music Library source.

### Requirements

- NAS mode enabled on the B3+: **Settings & Tools → Maintenance → Start NAS**
- B3+ and Mac on the same network

### Usage

**Double-click ListBrennanNAS:**
1. Double-click **ListBrennanNAS** in `/Applications`
2. Enter the B3+'s IP address when prompted (find it at **Settings → Network → IP Address** on the B3+)
3. The report opens automatically in TextEdit

**Command line:**
```bash
bash ~/github/Brennan_MacOS_Utils/scripts/list_brennan_nas.sh 192.168.x.x
```

---

## Configuring the Brennan B3+ NAS as a Sonos Music Library

Once NAS mode is enabled, Sonos can index and play the B3+'s music collection directly.

### 1. Enable NAS mode on the B3+

On the B3+: **Settings & Tools → Maintenance → Start NAS**

The unit reboots once; the setting persists across reboots.

### 2. Find the B3+'s IP address

On the B3+: **Settings → Network → IP Address** (e.g. `192.168.1.50`)

### 3. Add the share in the Sonos app

1. Open the Sonos app on Mac
2. Go to **Manage → Music Library Settings → Add Music Source**
3. Enter the share path:
   ```
   \\192.168.1.50\music
   ```
   *(replace with your B3+'s actual IP address)*
4. Enter credentials:
   - **Username:** `root`
   - **Password:** `brennan`
5. Allow Sonos to index the library — this can take several minutes for large collections

> **SMB version note:** Sonos S2 hardware requires SMBv2 or SMBv3 (SMBv1 is not supported).
> If the connection fails, ensure your B3+ is running the latest firmware from
> [brennan.co.uk/pages/latest-software](https://brennan.co.uk/pages/latest-software).

---

## Installation

### 1. Install Homebrew (if not already installed)

[Homebrew](https://brew.sh) is a macOS package manager:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Verify:
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

This compiles all AppleScripts and installs them to `/Applications`:
- **BrennanTransfer.app** — process Qobuz FLAC files for Brennan/Sonos
- **ReleaseSonosSession.app** — release Spotify Connect on a Sonos speaker
- **ListBrennanNAS.app** — list artists, albums and track counts on the B3+ NAS

---

## Files

| File | Purpose |
|------|---------|
| `scripts/process_qobuz_flac.sh` | Strips artwork and downsamples Qobuz FLAC files, writes log |
| `scripts/release_sonos_session.sh` | Discovers Sonos speakers and releases Spotify Connect session |
| `scripts/list_brennan_nas.sh` | Mounts B3+ NAS and lists artists, albums and track counts |
| `automator/ProcessQobuzFLAC.applescript` | AppleScript source for BrennanTransfer.app |
| `automator/ReleaseSonosSession.applescript` | AppleScript source for ReleaseSonosSession.app |
| `automator/ListBrennanNAS.applescript` | AppleScript source for ListBrennanNAS.app |
| `install_automator_app.sh` | Compiles and installs all apps to `/Applications` |

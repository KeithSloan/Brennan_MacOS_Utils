#!/usr/bin/env bash
# list_sonos_library.sh
# Connects to any discovered Sonos speaker and lists the shared Music Library
# by artist and album, writing a report to ~/Music/BrennanMusic/sonos_library.txt.
#
# Requires: pip3 install soco
#
# Usage: list_sonos_library.sh

set -euo pipefail

REPORT_FILE="${HOME}/Music/BrennanMusic/sonos_library.txt"

# Find a Python installation that has soco — miniconda, Homebrew, or PATH
find_python3() {
    for p in \
        "${HOME}/miniconda3/bin/python3" \
        "${HOME}/opt/miniconda3/bin/python3" \
        "/opt/miniconda3/bin/python3" \
        "/opt/homebrew/bin/python3" \
        "/usr/local/bin/python3" \
        "$(command -v python3 2>/dev/null)"; do
        [[ -x "$p" ]] && "$p" -c "import soco" 2>/dev/null && echo "$p" && return 0
    done
    return 1
}

if ! PYTHON3=$(find_python3); then
    osascript -e 'display dialog "soco not installed.\nRun: pip3 install soco" buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

osascript -e 'display notification "Connecting to Sonos Music Library…" with title "Sonos Library"'

RESULT=$("$PYTHON3" - <<'PYEOF' || true
import soco, sys, os, datetime, subprocess
from collections import defaultdict

# Discover speakers — the Music Library is shared across all of them
speakers = sorted(soco.discover(timeout=10) or [], key=lambda s: s.player_name)

if not speakers:
    # Discovery failed — fall back to direct IP connection
    script = 'text returned of (display dialog "Sonos speaker not found automatically. Enter the speaker IP address:" default answer "192.168.1.84" buttons {"Cancel", "OK"} default button "OK")'
    result = subprocess.run(["osascript", "-e", script], capture_output=True, text=True)
    ip = result.stdout.strip()
    if not ip or ip == "false":
        print("CANCEL:")
        sys.exit(0)
    try:
        s = soco.SoCo(ip)
        _ = s.player_name  # test the connection
        speakers = [s]
    except Exception as e:
        print(f"ERR:Could not connect to Sonos at {ip}: {e}")
        sys.exit(1)

speaker = speakers[0]
ml = speaker.music_library

# Fetch all albums and all tracks in one pass each
try:
    albums = list(ml.get_albums(complete_result=True))
    tracks = list(ml.get_tracks(complete_result=True))
except Exception as e:
    print(f"ERR:Could not read Sonos Music Library: {e}")
    sys.exit(1)

if not albums:
    print("ERR:Sonos Music Library appears to be empty or has not finished indexing.")
    sys.exit(1)

# Count tracks per (artist_casefold, album_casefold)
track_counts = defaultdict(int)
for track in tracks:
    artist = (track.creator or "Unknown Artist").strip()
    album  = (track.album   or "Unknown Album").strip()
    track_counts[(artist.casefold(), album.casefold())] += 1

# Group albums by artist
by_artist = defaultdict(list)
for album in albums:
    artist = (album.creator or "Unknown Artist").strip()
    title  = (album.title   or "Unknown Album").strip()
    by_artist[artist].append(title)

# Write report
os.makedirs(os.path.expanduser("~/Music/BrennanMusic"), exist_ok=True)
report_path = os.path.expanduser("~/Music/BrennanMusic/sonos_library.txt")

artist_count = len(by_artist)
album_count  = len(albums)
track_count  = len(tracks)

with open(report_path, "w") as f:
    f.write(f"Sonos Music Library — {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    f.write(f"Source speaker : {speaker.player_name}\n")
    f.write("---\n")
    f.write(f"Artists : {artist_count}\n")
    f.write(f"Albums  : {album_count}\n")
    f.write(f"Tracks  : {track_count}\n")
    f.write("---\n\n")

    for artist in sorted(by_artist.keys(), key=str.casefold):
        f.write(f"{artist}/\n")
        for album_title in sorted(by_artist[artist], key=str.casefold):
            n = track_counts.get((artist.casefold(), album_title.casefold()), 0)
            f.write(f"  {album_title:<50}  ({n} tracks)\n")
        f.write("\n")

print(f"OK:{artist_count} artists · {album_count} albums · {track_count} tracks")
PYEOF
)

if [[ "$RESULT" == OK:* ]]; then
    open -a TextEdit "$REPORT_FILE"
    osascript -e "display notification \"${RESULT#OK:} — report saved\" with title \"Sonos Library\""
    echo "${RESULT#OK:} — report saved to ${REPORT_FILE}"
else
    MSG="${RESULT#ERR:}"
    osascript -e "display dialog \"$MSG\" buttons {\"OK\"} default button \"OK\" with icon stop"
    exit 1
fi

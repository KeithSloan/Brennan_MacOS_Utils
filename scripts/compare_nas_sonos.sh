#!/usr/bin/env bash
# compare_nas_sonos.sh
# Compares the Brennan B3+ NAS music contents with the Sonos Music Library
# and reports discrepancies:
#   • Albums on the NAS but missing from Sonos (not yet indexed)
#   • Albums in Sonos but missing from the NAS (removed or metadata mismatch)
#
# Requires:
#   • NAS mode enabled on the B3+: Settings & Tools → Maintenance → Start NAS
#   • pip3 install soco
#
# Usage: compare_nas_sonos.sh [IP_ADDRESS]

set -euo pipefail

SHARE_USER="root"
SHARE_PASS="brennan"
SHARE_NAME="music"
MOUNT_POINT="/tmp/brennan_nas_$$"
REPORT_FILE="${HOME}/Music/BrennanMusic/nas_sonos_comparison.txt"

if ! python3 -c "import soco" 2>/dev/null; then
    osascript -e 'display dialog "soco not installed.\nRun: pip3 install soco" buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# ── IP address ────────────────────────────────────────────────────────────────

if [[ $# -ge 1 ]]; then
    B3_IP="$1"
else
    B3_IP=$(osascript -e 'text returned of (display dialog "Enter Brennan B3+ IP address:" default answer "" buttons {"Cancel", "OK"} default button "OK")' 2>/dev/null || true)
fi

if [[ -z "$B3_IP" ]]; then
    exit 0   # user cancelled
fi

osascript -e 'display notification "Reading NAS and Sonos library…" with title "NAS vs Sonos"'

# ── Mount NAS ─────────────────────────────────────────────────────────────────

mkdir -p "$MOUNT_POINT"

cleanup() {
    if mount | grep -q "$MOUNT_POINT" 2>/dev/null; then
        diskutil unmount "$MOUNT_POINT" 2>/dev/null || umount "$MOUNT_POINT" 2>/dev/null || true
    fi
    rmdir "$MOUNT_POINT" 2>/dev/null || true
}
trap cleanup EXIT

if ! mount_smbfs "//${SHARE_USER}:${SHARE_PASS}@${B3_IP}/${SHARE_NAME}" "$MOUNT_POINT" 2>/dev/null; then
    osascript -e "display dialog \"Could not connect to Brennan NAS at ${B3_IP}.\n\nCheck:\n  • NAS mode is enabled (Settings → Maintenance → Start NAS)\n  • IP address is correct\n  • Mac and B3+ are on the same network\" buttons {\"OK\"} default button \"OK\" with icon stop"
    exit 1
fi

# ── Compare ───────────────────────────────────────────────────────────────────

RESULT=$(python3 - "$MOUNT_POINT" <<'PYEOF'
import sys, os, soco, datetime
from collections import defaultdict

mount_point = sys.argv[1]

# ── NAS contents (folder names) ───────────────────────────────────────────────

nas_albums = {}   # (artist_lower, album_lower) → (artist_display, album_display)

for artist_entry in os.scandir(mount_point):
    if not artist_entry.is_dir():
        continue
    artist_name = artist_entry.name
    for album_entry in os.scandir(artist_entry.path):
        if not album_entry.is_dir():
            continue
        album_name = album_entry.name
        key = (artist_name.casefold(), album_name.casefold())
        nas_albums[key] = (artist_name, album_name)

# ── Sonos library (metadata) ──────────────────────────────────────────────────

speakers = sorted(soco.discover(timeout=5) or [], key=lambda s: s.player_name)
if not speakers:
    print("ERR:No Sonos speakers found on network.")
    sys.exit(1)

ml = speakers[0].music_library

try:
    sonos_album_list = list(ml.get_albums(complete_result=True))
except Exception as e:
    print(f"ERR:Could not read Sonos Music Library: {e}")
    sys.exit(1)

sonos_albums = {}  # (artist_lower, album_lower) → (artist_display, album_display)
for album in sonos_album_list:
    artist = (album.creator or "Unknown Artist").strip()
    title  = (album.title  or "Unknown Album").strip()
    key = (artist.casefold(), title.casefold())
    sonos_albums[key] = (artist, title)

# ── Discrepancies ─────────────────────────────────────────────────────────────

nas_only   = {k: v for k, v in nas_albums.items()   if k not in sonos_albums}
sonos_only = {k: v for k, v in sonos_albums.items() if k not in nas_albums}

# ── Report ────────────────────────────────────────────────────────────────────

os.makedirs(os.path.expanduser("~/Music/BrennanMusic"), exist_ok=True)
report_path = os.path.expanduser("~/Music/BrennanMusic/nas_sonos_comparison.txt")

with open(report_path, "w") as f:
    f.write(f"NAS vs Sonos Comparison — {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    f.write(f"NAS   : {len(nas_albums)} albums across {len({k[0] for k in nas_albums})} artists\n")
    f.write(f"Sonos : {len(sonos_albums)} albums across {len({k[0] for k in sonos_albums})} artists\n")
    f.write("---\n\n")

    if not nas_only and not sonos_only:
        f.write("No discrepancies found — NAS and Sonos library are in sync.\n")
    else:
        if nas_only:
            f.write(f"ON NAS BUT MISSING FROM SONOS ({len(nas_only)}) ────────────────────────────\n")
            f.write("These albums are on the B3+ NAS but have not been indexed by Sonos.\n")
            f.write("Tip: trigger a library rescan in the Sonos app.\n\n")
            current_artist = None
            for artist, album in sorted(nas_only.values(), key=lambda x: (x[0].casefold(), x[1].casefold())):
                if artist != current_artist:
                    f.write(f"  {artist}/\n")
                    current_artist = artist
                f.write(f"    {album}\n")
            f.write("\n")

        if sonos_only:
            f.write(f"IN SONOS BUT MISSING FROM NAS ({len(sonos_only)}) ─────────────────────────────\n")
            f.write("These albums are in the Sonos index but no matching folder was found on the NAS.\n")
            f.write("This may indicate deleted files or a metadata/folder name mismatch.\n\n")
            current_artist = None
            for artist, album in sorted(sonos_only.values(), key=lambda x: (x[0].casefold(), x[1].casefold())):
                if artist != current_artist:
                    f.write(f"  {artist}/\n")
                    current_artist = artist
                f.write(f"    {album}\n")
            f.write("\n")

nas_only_count   = len(nas_only)
sonos_only_count = len(sonos_only)
print(f"OK:{nas_only_count} missing from Sonos · {sonos_only_count} missing from NAS")
PYEOF
)

# ── Done ──────────────────────────────────────────────────────────────────────

if [[ "$RESULT" == OK:* ]]; then
    open -a TextEdit "$REPORT_FILE"
    osascript -e "display notification \"${RESULT#OK:} — report saved\" with title \"NAS vs Sonos\""
    echo "${RESULT#OK:} — report saved to ${REPORT_FILE}"
else
    MSG="${RESULT#ERR:}"
    osascript -e "display dialog \"$MSG\" buttons {\"OK\"} default button \"OK\" with icon stop"
    exit 1
fi

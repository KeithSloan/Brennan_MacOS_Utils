#!/usr/bin/env bash
# list_brennan_nas.sh
# Mounts the Brennan B3+ NAS share, lists its music contents by
# artist and album, writes a report, then unmounts cleanly.
#
# Requires NAS mode enabled on the B3:
#   Settings & Tools → Maintenance → Start NAS
#
# Usage: list_brennan_nas.sh [IP_ADDRESS]

set -euo pipefail

SHARE_USER="root"
SHARE_PASS="brennan"
SHARE_NAME="music"
MOUNT_POINT="/tmp/brennan_nas_$$"
REPORT_FILE="${HOME}/Music/BrennanMusic/nas_contents.txt"

# ── IP address ────────────────────────────────────────────────────────────────

if [[ $# -ge 1 ]]; then
    B3_IP="$1"
else
    B3_IP=$(osascript -e 'text returned of (display dialog "Enter Brennan B3+ IP address:" default answer "" buttons {"Cancel", "OK"} default button "OK")' 2>/dev/null || true)
fi

if [[ -z "$B3_IP" ]]; then
    exit 0   # user cancelled
fi

# ── Mount ─────────────────────────────────────────────────────────────────────

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

# ── Counts ────────────────────────────────────────────────────────────────────

ARTIST_COUNT=$(find "$MOUNT_POINT" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
ALBUM_COUNT=$(find  "$MOUNT_POINT" -mindepth 2 -maxdepth 2 -type d | wc -l | tr -d ' ')
TRACK_COUNT=$(find  "$MOUNT_POINT" -mindepth 3 \
    \( -iname "*.flac" -o -iname "*.mp3" -o -iname "*.wav" -o -iname "*.m4a" \) | wc -l | tr -d ' ')

# ── Report ────────────────────────────────────────────────────────────────────

mkdir -p "$(dirname "$REPORT_FILE")"

{
    echo "Brennan B3+ NAS Contents — $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Share : //${B3_IP}/${SHARE_NAME}"
    echo "---"
    printf "Artists : %s\n" "$ARTIST_COUNT"
    printf "Albums  : %s\n" "$ALBUM_COUNT"
    printf "Tracks  : %s\n" "$TRACK_COUNT"
    echo "---"
    echo ""

    while IFS= read -r artist_dir; do
        artist="$(basename "$artist_dir")"
        echo "${artist}/"
        while IFS= read -r album_dir; do
            album="$(basename "$album_dir")"
            track_n=$(find "$album_dir" \
                \( -iname "*.flac" -o -iname "*.mp3" -o -iname "*.wav" -o -iname "*.m4a" \) | wc -l | tr -d ' ')
            printf "  %-50s  (%s tracks)\n" "${album}" "$track_n"
        done < <(find "$artist_dir" -mindepth 1 -maxdepth 1 -type d | sort)
        echo ""
    done < <(find "$MOUNT_POINT" -mindepth 1 -maxdepth 1 -type d | sort)
} > "$REPORT_FILE"

# ── Done ──────────────────────────────────────────────────────────────────────

open -a TextEdit "$REPORT_FILE"
osascript -e "display notification \"${ARTIST_COUNT} artists · ${ALBUM_COUNT} albums · ${TRACK_COUNT} tracks — report saved\" with title \"Brennan NAS\""
echo "OK:${ARTIST_COUNT} artists, ${ALBUM_COUNT} albums, ${TRACK_COUNT} tracks — report saved to ${REPORT_FILE}"

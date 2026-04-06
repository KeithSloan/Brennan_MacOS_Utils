#!/usr/bin/env bash
# process_qobuz_flac.sh
# Strips embedded artwork from FLAC files for Sonos/Brennan compatibility.
# Audio is copied losslessly; all metadata tags are preserved.
# Preserves full subdirectory structure under TRANSFERS_ROOT.
#
# Usage: process_qobuz_flac.sh <directory>

set -euo pipefail

FFMPEG="/opt/homebrew/bin/ffmpeg"
TRANSFERS_ROOT="${HOME}/Music/BrennanMusic/Transfer"

notify() {
    osascript -e "display notification \"$1\" with title \"Process Qobuz FLAC\""
}

if [[ $# -lt 1 ]]; then
    osascript -e 'display dialog "No folder supplied." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

SOURCE_DIR="${1%/}"

if [[ ! -d "$SOURCE_DIR" ]]; then
    osascript -e "display dialog \"Not a directory:\n$SOURCE_DIR\" buttons {\"OK\"} default button \"OK\" with icon stop"
    exit 1
fi

if [[ ! -x "$FFMPEG" ]]; then
    osascript -e 'display dialog "ffmpeg not found at /opt/homebrew/bin/ffmpeg\nInstall with: brew install ffmpeg" buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Clear any previous output before starting fresh
if [[ -d "$TRANSFERS_ROOT" ]]; then
    rm -rf "$TRANSFERS_ROOT"
fi
mkdir -p "$TRANSFERS_ROOT"

# Count FLAC files first so we can report zero-found early
FLAC_COUNT=$(find "$SOURCE_DIR" -iname "*.flac" | wc -l | tr -d ' ')

if [[ "$FLAC_COUNT" -eq 0 ]]; then
    osascript -e "display dialog \"No FLAC files found in:\n$SOURCE_DIR\" buttons {\"OK\"} default button \"OK\" with icon caution"
    exit 0
fi

notify "Starting — $FLAC_COUNT FLAC files found in $(basename "$SOURCE_DIR")"

PROCESSED=0
ERRORS=0

while IFS= read -r -d '' FLAC_FILE; do
    REL_PATH="${FLAC_FILE#"$SOURCE_DIR/"}"
    OUT_FILE="${TRANSFERS_ROOT}/${REL_PATH}"
    mkdir -p "$(dirname "$OUT_FILE")"

    if "$FFMPEG" \
        -i "$FLAC_FILE" \
        -map 0:a \
        -map_metadata 0 \
        -c:a copy \
        -y \
        "$OUT_FILE" \
        2>/dev/null; then
        PROCESSED=$((PROCESSED + 1))
    else
        ERRORS=$((ERRORS + 1))
    fi
done < <(find "$SOURCE_DIR" -iname "*.flac" -print0 | sort -z)

if [[ $ERRORS -eq 0 ]]; then
    echo "OK:$PROCESSED files processed successfully."
else
    echo "ERR:Finished with errors. Processed: $PROCESSED  Errors: $ERRORS"
fi

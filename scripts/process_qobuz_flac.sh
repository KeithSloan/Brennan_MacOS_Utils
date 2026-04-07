#!/usr/bin/env bash
# process_qobuz_flac.sh
# Strips embedded artwork from FLAC files for Sonos/Brennan compatibility.
# Audio is copied losslessly; all metadata tags are preserved.
# Preserves full subdirectory structure under TRANSFERS_ROOT.
#
# Usage: process_qobuz_flac.sh <directory>

set -euo pipefail

FFMPEG="/opt/homebrew/bin/ffmpeg"
FFPROBE="/opt/homebrew/bin/ffprobe"
TRANSFERS_ROOT="${HOME}/Music/BrennanMusic/Transfer"
LOG_FILE="${HOME}/Music/BrennanMusic/process_qobuz_flac.log"

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

if [[ ! -x "$FFPROBE" ]]; then
    osascript -e 'display dialog "ffprobe not found at /opt/homebrew/bin/ffprobe\nInstall with: brew install ffmpeg" buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Clear any previous output before starting fresh
if [[ -d "$TRANSFERS_ROOT" ]]; then
    rm -rf "$TRANSFERS_ROOT"
fi
mkdir -p "$TRANSFERS_ROOT"

# Initialise log
mkdir -p "$(dirname "$LOG_FILE")"
{
    echo "Process Qobuz FLAC — $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Source: $SOURCE_DIR"
    echo "---"
} > "$LOG_FILE"

# Count FLAC files first so we can report zero-found early
FLAC_COUNT=$(find "$SOURCE_DIR" -iname "*.flac" | wc -l | tr -d ' ')

if [[ "$FLAC_COUNT" -eq 0 ]]; then
    osascript -e "display dialog \"No FLAC files found in:\n$SOURCE_DIR\" buttons {\"OK\"} default button \"OK\" with icon caution"
    exit 0
fi

notify "Starting — $FLAC_COUNT FLAC files found in $(basename "$SOURCE_DIR")"

PROCESSED=0
ERRORS=0
ART_REMOVED=0
RESAMPLED=0

while IFS= read -r -d '' FLAC_FILE; do
    REL_PATH="${FLAC_FILE#"$SOURCE_DIR/"}"
    OUT_FILE="${TRANSFERS_ROOT}/${REL_PATH}"
    mkdir -p "$(dirname "$OUT_FILE")"

    SAMPLE_RATE=$("$FFPROBE" -v error -select_streams a:0 \
        -show_entries stream=sample_rate -of default=noprint_wrappers=1:nokey=1 \
        "$FLAC_FILE" 2>/dev/null)

    HAS_ART=$("$FFPROBE" -v error -select_streams v \
        -show_entries stream=codec_type -of default=noprint_wrappers=1:nokey=1 \
        "$FLAC_FILE" 2>/dev/null)

    LOG_NOTES=()
    [[ -n "$HAS_ART" ]] && LOG_NOTES+=("artwork removed")

    if [[ "$SAMPLE_RATE" -gt 48000 ]]; then
        AUDIO_OPTS=(-c:a flac -ar 48000)
        LOG_NOTES+=("resampled ${SAMPLE_RATE}Hz → 48000Hz")
    else
        AUDIO_OPTS=(-c:a copy)
    fi

    if "$FFMPEG" \
        -i "$FLAC_FILE" \
        -map 0:a \
        -map_metadata 0 \
        "${AUDIO_OPTS[@]}" \
        -y \
        "$OUT_FILE" \
        2>/dev/null; then
        PROCESSED=$((PROCESSED + 1))
        [[ -n "$HAS_ART" ]] && ART_REMOVED=$((ART_REMOVED + 1))
        [[ "$SAMPLE_RATE" -gt 48000 ]] && RESAMPLED=$((RESAMPLED + 1))
        if [[ ${#LOG_NOTES[@]} -gt 0 ]]; then
            NOTE_STR=$(IFS=', '; echo "${LOG_NOTES[*]}")
            echo "  [${NOTE_STR}] ${REL_PATH}" >> "$LOG_FILE"
        fi
    else
        ERRORS=$((ERRORS + 1))
        echo "  [ERROR] ${REL_PATH}" >> "$LOG_FILE"
    fi
done < <(find "$SOURCE_DIR" -iname "*.flac" -print0 | sort -z)

{
    echo "---"
    echo "Processed : $PROCESSED"
    echo "Artwork removed : $ART_REMOVED"
    echo "Resampled : $RESAMPLED"
    [[ $ERRORS -gt 0 ]] && echo "Errors    : $ERRORS"
    echo "Completed : $(date '+%Y-%m-%d %H:%M:%S')"
} >> "$LOG_FILE"

if [[ $ERRORS -eq 0 ]]; then
    echo "OK:$PROCESSED files processed successfully."
else
    echo "ERR:Finished with errors. Processed: $PROCESSED  Errors: $ERRORS"
fi

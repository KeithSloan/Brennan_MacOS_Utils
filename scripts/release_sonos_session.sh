#!/usr/bin/env bash
# release_sonos_session.sh
# Stops playback on the Sonos 'Family Room' speaker to release
# any active Spotify Connect session, freeing it for the Brennan Web UI.
#
# Requires: pip3 install soco
#
# Usage: release_sonos_session.sh

set -euo pipefail

SPEAKER_NAME="Family Room"

if ! python3 -c "import soco" 2>/dev/null; then
    osascript -e 'display dialog "soco not installed.\nRun: pip3 install soco" buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

RESULT=$(python3 - <<PYEOF
import soco, sys

name = "$SPEAKER_NAME"
speakers = soco.discover(timeout=5) or []
speaker = next((s for s in speakers if s.player_name == name), None)

if not speaker:
    print(f"ERR:Speaker '{name}' not found on network.")
    sys.exit(1)

try:
    speaker.stop()
    print(f"OK:'{name}' released — Brennan Web UI can now take control.")
except Exception as e:
    print(f"ERR:{e}")
    sys.exit(1)
PYEOF
)

if [[ "$RESULT" == OK:* ]]; then
    osascript -e "display notification \"${RESULT#OK:}\" with title \"Sonos Release\""
    echo "${RESULT#OK:}"
else
    MSG="${RESULT#ERR:}"
    osascript -e "display dialog \"$MSG\" buttons {\"OK\"} default button \"OK\" with icon stop"
    exit 1
fi

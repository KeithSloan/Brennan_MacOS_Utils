#!/usr/bin/env bash
# release_sonos_session.sh
# Discovers Sonos speakers on the network, prompts the user to pick one,
# then stops playback to release any active Spotify Connect session,
# freeing the speaker for the Brennan Web UI.
#
# Requires: pip3 install soco
#
# Usage: release_sonos_session.sh

set -euo pipefail

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

RESULT=$("$PYTHON3" - <<'PYEOF' || true
import soco, sys, subprocess

speakers = sorted(soco.discover(timeout=10) or [], key=lambda s: s.player_name)

if not speakers:
    # Discovery failed — fall back to direct IP connection
    result = subprocess.run(
        ["osascript", "-e",
         'text returned of (display dialog "Sonos speaker not found automatically.\n'
         'Enter the speaker\'s IP address:" default answer "" buttons {"Cancel", "OK"} default button "OK")'],
        capture_output=True, text=True)
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

names = [s.player_name for s in speakers]
names_as = "{" + ", ".join(f'"{n}"' for n in names) + "}"
script = f'choose from list {names_as} with prompt "Select Sonos speaker to release:" default items {{"{names[0]}"}}'

result = subprocess.run(["osascript", "-e", script], capture_output=True, text=True)
chosen = result.stdout.strip()

if not chosen or chosen == "false":
    print("CANCEL:")
    sys.exit(0)

speaker = next((s for s in speakers if s.player_name == chosen), None)
if not speaker:
    print(f"ERR:Speaker '{chosen}' not found.")
    sys.exit(1)

try:
    speaker.stop()
    print(f"OK:'{chosen}' released — Brennan Web UI can now take control.")
except Exception as e:
    print(f"ERR:{e}")
    sys.exit(1)
PYEOF
)

if [[ "$RESULT" == CANCEL:* ]]; then
    exit 0
elif [[ "$RESULT" == OK:* ]]; then
    osascript -e "display notification \"${RESULT#OK:}\" with title \"Sonos Release\""
    echo "${RESULT#OK:}"
else
    MSG="${RESULT#ERR:}"
    osascript -e "display dialog \"$MSG\" buttons {\"OK\"} default button \"OK\" with icon stop"
    exit 1
fi

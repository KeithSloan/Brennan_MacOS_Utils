#!/usr/bin/env bash
# brennan_utils.sh
# Main launcher — presents a menu of all Brennan MacOS Utils and runs
# whichever the user selects.
#
# Usage: brennan_utils.sh

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Menu ──────────────────────────────────────────────────────────────────────

CHOICE=$(osascript <<'ASEOF'
choose from list {¬
    "Process Qobuz FLAC for Brennan", ¬
    "Release Sonos Session", ¬
    "List Brennan NAS Contents", ¬
    "List Sonos Music Library", ¬
    "Compare NAS vs Sonos Music Library"} ¬
    with prompt "Select a utility to run:" ¬
    default items {"Process Qobuz FLAC for Brennan"}
ASEOF
)

if [[ -z "$CHOICE" || "$CHOICE" == "false" ]]; then
    exit 0   # user cancelled
fi

# ── Dispatch ──────────────────────────────────────────────────────────────────

case "$CHOICE" in
    "Process Qobuz FLAC for Brennan")
        bash "${SCRIPTS_DIR}/process_qobuz_flac.sh"
        ;;
    "Release Sonos Session")
        bash "${SCRIPTS_DIR}/release_sonos_session.sh"
        ;;
    "List Brennan NAS Contents")
        bash "${SCRIPTS_DIR}/list_brennan_nas.sh"
        ;;
    "List Sonos Music Library")
        bash "${SCRIPTS_DIR}/list_sonos_library.sh"
        ;;
    "Compare NAS vs Sonos Music Library")
        bash "${SCRIPTS_DIR}/compare_nas_sonos.sh"
        ;;
esac

#!/usr/bin/env bash
# install_automator_app.sh
# Compiles AppleScripts into macOS apps and installs them to /Applications.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

install_app() {
    local src="$1"
    local dest="$2"
    echo "Compiling $(basename "$dest") ..."
    rm -rf "$dest"
    osacompile -o "$dest" "$src"
    echo "Installed to ${dest}"
}

install_app "${REPO_DIR}/automator/ProcessQobuzFLAC.applescript"   "/Applications/BrennanTransfer.app"
install_app "${REPO_DIR}/automator/ReleaseSonosSession.applescript" "/Applications/ReleaseSonosSession.app"

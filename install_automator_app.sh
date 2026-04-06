#!/usr/bin/env bash
# install_automator_app.sh
# Compiles ProcessQobuzFLAC.applescript into BrennanTransfer.app
# and installs it to /Applications.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
APPLESCRIPT_SRC="${REPO_DIR}/automator/ProcessQobuzFLAC.applescript"
APP_DEST="/Applications/BrennanTransfer.app"

echo "Compiling BrennanTransfer.app ..."

rm -rf "$APP_DEST"
osacompile -o "$APP_DEST" "$APPLESCRIPT_SRC"

echo "Installed to ${APP_DEST}"

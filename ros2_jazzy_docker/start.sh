#!/bin/bash
# ──────────────────────────────────────────────────────────────────────────────
# start.sh — Start the Tmuxinator session.
# Usage: ./start.sh [path/to/_setup.sh]
# ──────────────────────────────────────────────────────────────────────────────

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
cd "$SCRIPTPATH"

# Symlink session.yml so tmuxinator finds it
rm -f .tmuxinator.yml
ln -s session.yml .tmuxinator.yml

SETUP_NAME="${1:-$SCRIPTPATH/_setup.sh}"

tmuxinator start ros2_session setup_name="$SETUP_NAME"

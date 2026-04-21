#!/bin/bash
# ──────────────────────────────────────────────────────────────────────────────
# _setup.sh — Project-level environment setup.
# This script is sourced by tmuxinator before each pane command.
# Customise it for your project.
# ──────────────────────────────────────────────────────────────────────────────

# Always source ROS2 base
source /opt/ros/jazzy/setup.bash

# Source your workspace if it has been built
WS="$HOME/ros2_ws"
if [ -f "$WS/install/setup.bash" ]; then
    source "$WS/install/setup.bash"
fi

# ── Project-specific variables (edit as needed) ───────────────────────────────
# export MY_ROBOT_IP=192.168.1.100
# export ROS_DOMAIN_ID=42

# ── SSH agent check (informational) ──────────────────────────────────────────
if ! ssh-add -l > /dev/null 2>&1; then
    echo "[!] SSH agent not forwarded — git push/pull over SSH will fail."
    echo "    Make sure you started the container with first_run.sh while"
    echo "    ssh-agent was running on the host."
fi

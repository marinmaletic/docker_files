#!/usr/bin/env bash
# Opens a shell in a project container; starts it first if stopped.
# Refreshes xauth so GUI apps keep working after a host reboot.
#
#   ./exec.sh ros2_ur10e
#   ./exec.sh              (lists containers created by run.sh)
set -euo pipefail

if [ $# -eq 0 ]; then
  echo "Project containers:"
  docker ps -a --filter "label=devenv=1" \
    --format "  {{.Names}}\t{{.Status}}\t{{.Label \"devenv.env\"}}"
  echo
  echo "usage: exec.sh <container-name>"
  exit 0
fi

CONTAINER="${1}"

if [ -z "$(docker ps -aq -f "name=^/${CONTAINER}$")" ]; then
  echo "No container '${CONTAINER}'. Create it: run.sh <path-to-project-repo>"
  echo "(remember the prefix: ros2_<name> or dev_<name>)"
  exit 1
fi

XAUTH=/tmp/.docker.xauth
touch "${XAUTH}"
xauth nlist "${DISPLAY}" | sed -e 's/^..../ffff/' | xauth -f "${XAUTH}" nmerge - 2>/dev/null || true
chmod a+r "${XAUTH}"

[ -z "$(docker ps -q -f "name=^/${CONTAINER}$")" ] && docker start "${CONTAINER}" >/dev/null

exec docker exec -it -e DISPLAY="${DISPLAY}" "${CONTAINER}" bash

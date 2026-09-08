#!/usr/bin/env bash
# Builds an environment image.
#
#   ./scripts/build.sh                                  -> lists environments
#   ./scripts/build.sh ubuntu24.04-jazzy-cuda12.6
#   ./scripts/build.sh ubuntu24.04-cuda12.6 --no-cache
#
# Build context is the repo root so envs/ and common/ are both reachable.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ $# -eq 0 ]; then
  echo "Environments:"
  for d in "${REPO_ROOT}"/envs/*/; do
    n="$(basename "$d")"
    desc="$(grep -m1 '^# Ubuntu' "$d/Dockerfile" 2>/dev/null | sed 's/^# //')"
    printf "  %-32s %s\n" "$n" "$desc"
  done
  echo
  echo "usage: build.sh <environment> [docker build flags]"
  exit 0
fi

ENV_NAME="$1"; shift
ENV_DIR="${REPO_ROOT}/envs/${ENV_NAME}"
[ -f "${ENV_DIR}/env.conf" ] || { echo "No such environment: ${ENV_NAME}"; exit 1; }

source "${ENV_DIR}/env.conf"
DATE_TAG="${TAG_FAMILY}-$(date +%Y-%m)"

docker build "$@" \
  -t "${IMAGE}:${DATE_TAG}" \
  -t "${IMAGE}:${TAG_FAMILY}" \
  --build-arg USERNAME="${USER}" \
  --build-arg UID="$(id -u)" \
  --build-arg GID="$(id -g)" \
  -f "${ENV_DIR}/Dockerfile" \
  "${REPO_ROOT}"

echo
echo "Built:"
echo "  ${IMAGE}:${DATE_TAG}     <- pin THIS in a project's .container-env"
echo "  ${IMAGE}:${TAG_FAMILY}   <- moving alias, fine for scratch work"

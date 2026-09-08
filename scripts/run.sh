#!/usr/bin/env bash
# Creates a container for a project repo that lives outside this repo.
#
#   ./run.sh ~/dev/ur10e                    -> container "ros2_ur10e"
#   ./run.sh ~/dev/ur10e arm_exp            -> container "ros2_arm_exp"
#   ./run.sh ~/dev/vision-thing             -> "dev_vision-thing" if the
#                                              project's .container-env
#                                              selects the non-ROS env
#
# Prefix (ros2_ / dev_) comes from the environment's env.conf, so the name
# always tells you which stack is inside.
#
# The project repo IS the workspace: src/ at the repo root (ROS), or any
# layout you like (non-ROS). The whole repo, including .git, is mounted at
# ~/ws so git works inside the container.
#
# Run ONCE per project; afterwards use exec.sh. Recreating costs nothing —
# all work lives in the host repo.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$(cd "${1:?usage: run.sh <path-to-project-repo> [name]}" && pwd)"
NAME="${2:-$(basename "${PROJECT_DIR}")}"

# --- environment selection (override per project in .container-env) --------
ENV_NAME="${ENV_NAME:-ubuntu24.04-jazzy-cuda12.6}"
IMAGE_TAG=""            # empty -> use TAG_FAMILY from env.conf
EXTRA_ARGS=()
[ -f "${PROJECT_DIR}/.container-env" ] && source "${PROJECT_DIR}/.container-env"

ENV_DIR="${REPO_ROOT}/envs/${ENV_NAME}"
[ -f "${ENV_DIR}/env.conf" ] || { echo "No such environment: ${ENV_NAME}"; exit 1; }
source "${ENV_DIR}/env.conf"

CONTAINER="${PREFIX}${NAME}"
FINAL_IMAGE="${IMAGE}:${IMAGE_TAG:-${TAG_FAMILY}}"

# --- workspace sanity -----------------------------------------------------
if [ "${HAS_ROS}" = "1" ] && [ ! -d "${PROJECT_DIR}/src" ]; then
  echo "No src/ at ${PROJECT_DIR}."
  echo "For a ROS project the repo root is the colcon workspace:"
  echo "  mkdir -p ${PROJECT_DIR}/src"
  exit 1
fi
[ -d "${PROJECT_DIR}/.git" ] || echo "[!] ${PROJECT_DIR} is not a git repo yet (git init)."

# --- optional project image layer (project-only deps) ---------------------
if [ -f "${PROJECT_DIR}/docker/Dockerfile" ]; then
  BASE="${FINAL_IMAGE}"
  FINAL_IMAGE="${CONTAINER}-img:local"
  echo "[*] Project Dockerfile found — building ${FINAL_IMAGE} from ${BASE}"
  docker build \
    --build-arg BASE_IMAGE="${BASE}" \
    --build-arg USERNAME="${USER}" \
    -t "${FINAL_IMAGE}" \
    -f "${PROJECT_DIR}/docker/Dockerfile" \
    "${PROJECT_DIR}/docker"
fi

# --- ROS domain: deterministic per container, so two ROS projects running
# --- simultaneously on --net=host don't discover each other's nodes.
ROS_ARGS=()
if [ "${HAS_ROS}" = "1" ]; then
  if [ -z "${ROS_DOMAIN_ID:-}" ]; then
    ROS_DOMAIN_ID=$(( ( $(echo -n "${CONTAINER}" | cksum | cut -d' ' -f1) % 100 ) + 1 ))
  fi
  ROS_ARGS+=(-e ROS_DOMAIN_ID="${ROS_DOMAIN_ID}")
fi

# --- xauth: rebuilt every run; /tmp is wiped at reboot --------------------
XAUTH=/tmp/.docker.xauth
touch "${XAUTH}"
xauth nlist "${DISPLAY}" | sed -e 's/^..../ffff/' | xauth -f "${XAUTH}" nmerge - 2>/dev/null || true
chmod a+r "${XAUTH}"

# --- git inside the container ---------------------------------------------
# .gitconfig read-only -> identity already set, no per-container setup
# ssh-agent socket     -> git push works; keys stay on the host
GIT_ARGS=()
[ -f "${HOME}/.gitconfig" ] && GIT_ARGS+=(-v "${HOME}/.gitconfig:/home/${USER}/.gitconfig:ro")
if [ -n "${SSH_AUTH_SOCK:-}" ]; then
  GIT_ARGS+=(-v "${SSH_AUTH_SOCK}:/ssh-agent" -e SSH_AUTH_SOCK=/ssh-agent)
else
  echo "[!] SSH_AUTH_SOCK unset — git push over SSH won't work in the container."
  echo "    On the HOST:  eval \$(ssh-agent -s) && ssh-add ~/.ssh/id_ed25519"
fi

if [ -n "$(docker ps -aq -f "name=^/${CONTAINER}$")" ]; then
  echo "Container '${CONTAINER}' already exists. Use exec.sh ${CONTAINER},"
  echo "or 'docker rm ${CONTAINER}' first to recreate it."
  exit 1
fi

echo "[*] environment : ${ENV_NAME}"
echo "[*] container   : ${CONTAINER}"
echo "[*] image       : ${FINAL_IMAGE}"
echo "[*] workspace   : ${PROJECT_DIR} -> /home/${USER}/ws"
[ "${HAS_ROS}" = "1" ] && echo "[*] ROS_DOMAIN_ID: ${ROS_DOMAIN_ID}"
echo

docker run -it \
  --name "${CONTAINER}" \
  --hostname "${NAME}" \
  --label devenv=1 \
  --label devenv.env="${ENV_NAME}" \
  --gpus all \
  --net=host \
  --ipc=host \
  -e DISPLAY="${DISPLAY}" \
  -e XAUTHORITY="${XAUTH}" \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -v "${XAUTH}:${XAUTH}:rw" \
  -v "${PROJECT_DIR}:/home/${USER}/ws" \
  "${ROS_ARGS[@]}" \
  "${GIT_ARGS[@]}" \
  "${EXTRA_ARGS[@]}" \
  "${FINAL_IMAGE}"

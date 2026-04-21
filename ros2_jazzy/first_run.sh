#!/bin/bash
# ──────────────────────────────────────────────────────────────────────────────
# first_run.sh — Creates and starts the container for the FIRST time.
# For subsequent runs use:
#   docker start -i ros2_jazzy_cont
#   docker exec -it ros2_jazzy_cont bash
# ──────────────────────────────────────────────────────────────────────────────

set -e

CONTAINER_NAME="ros2_jazzy_cont"
IMAGE_NAME="ros2_jazzy_img"

# ── X11 auth ──────────────────────────────────────────────────────────────────
XAUTH=/tmp/.docker.xauth

echo "[*] Preparing Xauthority data..."
xauth_list=$(xauth nlist :0 2>/dev/null | tail -n 1 | sed -e 's/^..../ffff/')

if [ ! -f "$XAUTH" ]; then
    if [ -n "$xauth_list" ]; then
        echo "$xauth_list" | xauth -f "$XAUTH" nmerge -
    else
        touch "$XAUTH"
    fi
    chmod a+r "$XAUTH"
fi

echo "[*] Xauth file: $(file $XAUTH)"
echo ""

# ── SSH agent forwarding ──────────────────────────────────────────────────────
SSH_AGENT_LINK="$HOME/.ssh/ssh_auth_sock"
if [ -n "$SSH_AUTH_SOCK" ]; then
    echo "[*] Linking SSH agent socket: $SSH_AUTH_SOCK -> $SSH_AGENT_LINK"
    ln -sf "$SSH_AUTH_SOCK" "$SSH_AGENT_LINK"
else
    echo "[!] WARNING: SSH_AUTH_SOCK is not set. Git SSH operations inside the"
    echo "    container will not work unless you run: eval \$(ssh-agent -s)"
fi

echo ""
echo "[*] Starting container '$CONTAINER_NAME' from image '$IMAGE_NAME'..."
echo ""

docker run -it \
    --name "$CONTAINER_NAME" \
    --env="DISPLAY=$DISPLAY" \
    --env="QT_X11_NO_MITSHM=1" \
    --env="TERM=xterm-256color" \
    --env="XAUTHORITY=$XAUTH" \
    --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
    --volume="$XAUTH:$XAUTH" \
    --volume="$SSH_AGENT_LINK:/ssh-agent:ro" \
    --env="SSH_AUTH_SOCK=/ssh-agent" \
    --volume="/dev:/dev" \
    --volume="/var/run/dbus/:/var/run/dbus/:z" \
    --net=host \
    --privileged \
    --gpus all \
    "$IMAGE_NAME"
# Ubuntu 24.04 (Noble) + CUDA 12.6 runtime + cuDNN — NO ROS.
# For ML / vision / numerics work outside the ROS stack.
#
# Built by:  ./scripts/build.sh ubuntu24.04-cuda12.6
# Build context is the REPO ROOT, so common/ is available to COPY.
#
# 'runtime' base = CUDA/cuDNN shared libs, no nvcc. PyTorch wheels bundle
# their own CUDA. Switch to 12.6.1-cudnn-devel-ubuntu24.04 if you need to
# compile CUDA code (custom ops, TensorRT plugins).

FROM nvidia/cuda:12.6.1-cudnn-runtime-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive

# ── Locale ────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales curl wget ca-certificates gnupg2 lsb-release \
    software-properties-common \
    && locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && add-apt-repository universe \
    && rm -rf /var/lib/apt/lists/*
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# ── Dev tools ─────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo git git-lfs \
    build-essential cmake ninja-build gdb \
    nano vim tmux \
    htop tree jq zip unzip \
    mesa-utils x11-apps \
    python3-pip python3-venv python3-dev bash-completion \
    && rm -rf /var/lib/apt/lists/*

# ── Python scientific stack (apt, coexists cleanly with system python) ────
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-numpy \
    python3-scipy \
    python3-matplotlib \
    python3-opencv \
    python3-pandas \
    && rm -rf /var/lib/apt/lists/*

# --- PyTorch: uncomment when needed (~2.5 GB layer) -----------------------
# RUN pip install --break-system-packages \
#     torch torchvision --index-url https://download.pytorch.org/whl/cu126

# ── Non-root user matching host UID/GID ───────────────────────────────────
# Noble base images ship an 'ubuntu' user at UID 1000 — remove it first.
ARG USERNAME=marin
ARG UID=1000
ARG GID=1000
RUN userdel -r ubuntu 2>/dev/null || true \
    && groupadd -g ${GID} ${USERNAME} 2>/dev/null || true \
    && useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME} \
    && usermod -aG video,dialout,plugdev ${USERNAME}

# ── GPU / display ─────────────────────────────────────────────────────────
# The CUDA base sets capabilities to compute,utility only — that gives
# llvmpipe for any GUI. 'graphics' makes the runtime inject libGLX_nvidia.
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute
ENV QT_X11_NO_MITSHM=1
ENV __NV_PRIME_RENDER_OFFLOAD=1
ENV __GLX_VENDOR_LIBRARY_NAME=nvidia

# ── Shared dotfiles ───────────────────────────────────────────────────────
COPY --chown=${UID}:${GID} common/config/aliases   /home/${USERNAME}/.bash_aliases
COPY --chown=${UID}:${GID} common/config/tmux.conf /home/${USERNAME}/.tmux.conf
COPY --chown=${UID}:${GID} common/config/nanorc    /home/${USERNAME}/.nanorc

USER ${USERNAME}
WORKDIR /home/${USERNAME}
CMD ["bash"]

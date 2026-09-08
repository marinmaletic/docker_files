# Ubuntu 24.04 (Noble) + ROS2 Jazzy + CUDA 12.6 runtime + cuDNN
#
# Built by:  ./scripts/build.sh ubuntu24.04-jazzy-cuda12.6
# Build context is the REPO ROOT, so common/ is available to COPY.
#
# NOTE: 'runtime' base = CUDA/cuDNN shared libs, NO nvcc. PyTorch wheels
# bundle their own CUDA and don't need nvcc. If you ever need to COMPILE
# CUDA code (custom torch ops, TensorRT plugins), change the tag to
# 12.6.1-cudnn-devel-ubuntu24.04 and rebuild — nothing else changes.

FROM nvidia/cuda:12.6.1-cudnn-runtime-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------------
# 1. Locale + apt basics
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales curl wget ca-certificates gnupg2 lsb-release \
    software-properties-common \
    && locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && add-apt-repository universe \
    && rm -rf /var/lib/apt/lists/*
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# ---------------------------------------------------------------------------
# 2. Dev tools (kept from your ros2_jazzy template, minus what git-on-host
#    makes unnecessary)
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo git git-lfs \
    build-essential cmake gdb \
    nano vim tmux tmuxinator \
    htop tree \
    mesa-utils x11-apps \
    python3-pip python3-venv bash-completion \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# 3. ROS2 apt source — CURRENT recommended method: the ros2-apt-source
#    package manages the repo config and signing keys and updates them
#    automatically (replaces the manual ros.key + sources.list.d dance,
#    which is the pattern that broke during the 2025 key rotation).
#    If this layer 404s, bump the ARG to the latest tag at:
#    https://github.com/ros-infrastructure/ros-apt-source/releases
# ---------------------------------------------------------------------------
ARG ROS_APT_SOURCE_VERSION=1.1.0
RUN curl -fL -o /tmp/ros2-apt-source.deb \
      "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo ${VERSION_CODENAME})_all.deb" \
    && apt-get update \
    && apt-get install -y /tmp/ros2-apt-source.deb \
    && rm -f /tmp/ros2-apt-source.deb \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# 4. ROS2 core + build tooling
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-jazzy-ros-base \
    ros-dev-tools \
    python3-rosdep \
    python3-colcon-common-extensions \
    python3-argcomplete \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# 5. URDF authoring + visualization
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-jazzy-rviz2 \
    ros-jazzy-urdf \
    ros-jazzy-urdf-tutorial \
    ros-jazzy-joint-state-publisher-gui \
    ros-jazzy-robot-state-publisher \
    ros-jazzy-xacro \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# 6. MoveIt2 + ros2_control (Setup Assistant is inside the moveit meta-pkg;
#    ros2_control + controllers are needed by the generated demo.launch.py)
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-jazzy-moveit \
    ros-jazzy-moveit-py \
    ros-jazzy-ros2-control \
    ros-jazzy-ros2-controllers \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# 7. Python scientific stack — from apt, NOT pip:
#    - coexists cleanly with ROS python deps
#    - python3-opencv instead of pip opencv-python, which ships its own
#      OpenCV and conflicts with cv_bridge's system OpenCV (ABI crashes)
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-numpy \
    python3-scipy \
    python3-matplotlib \
    python3-opencv \
    python3-transforms3d \
    && rm -rf /var/lib/apt/lists/*

# --- PyTorch (uncomment when you actually need it; ~2.5 GB layer) ----------
# RUN pip install --break-system-packages \
#     torch torchvision --index-url https://download.pytorch.org/whl/cu126

# ---------------------------------------------------------------------------
# 8. rosdep system init (user-level `rosdep update` happens below, as user)
# ---------------------------------------------------------------------------
RUN rosdep init

# ---------------------------------------------------------------------------
# 9. Non-root user matching host UID/GID.
#    Noble base images ship an 'ubuntu' user at UID 1000 — remove it first.
#    dialout/plugdev kept from your template for future serial/USB hardware.
# ---------------------------------------------------------------------------
ARG USERNAME=marin
ARG UID=1000
ARG GID=1000
RUN userdel -r ubuntu 2>/dev/null || true \
    && groupadd -g ${GID} ${USERNAME} 2>/dev/null || true \
    && useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME} \
    && usermod -aG video,dialout,plugdev ${USERNAME}

# ---------------------------------------------------------------------------
# 10. GPU / display environment.
#     The CUDA base sets NVIDIA_DRIVER_CAPABILITIES=compute,utility — that
#     alone gives you llvmpipe in RViz. 'graphics' makes the runtime inject
#     libGLX_nvidia. PRIME vars: Legion hybrid graphics offload.
# ---------------------------------------------------------------------------
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute
ENV QT_X11_NO_MITSHM=1
ENV __NV_PRIME_RENDER_OFFLOAD=1
ENV __GLX_VENDOR_LIBRARY_NAME=nvidia

# ---------------------------------------------------------------------------
# 11. Dotfiles (carried over from your ros2_jazzy repo — see setup notes
#     for the two edits) + shell config
# ---------------------------------------------------------------------------
COPY --chown=${UID}:${GID} common/config/aliases     /home/${USERNAME}/.bash_aliases
COPY --chown=${UID}:${GID} common/config/tmux.conf   /home/${USERNAME}/.tmux.conf
COPY --chown=${UID}:${GID} common/config/nanorc      /home/${USERNAME}/.nanorc
# ROS-only aliases live with the ROS environment, not in common/
COPY --chown=${UID}:${GID} envs/ubuntu24.04-jazzy-cuda12.6/config/aliases-ros \
     /home/${USERNAME}/.bash_aliases_ros

USER ${USERNAME}
WORKDIR /home/${USERNAME}

RUN rosdep update

RUN echo '' >> ~/.bashrc \
    && echo '# ── ROS2 ─────────────────────────────────────────────' >> ~/.bashrc \
    && echo 'source ~/.bash_aliases_ros' >> ~/.bashrc \
    && echo 'source /opt/ros/jazzy/setup.bash' >> ~/.bashrc \
    && echo '[ -f ~/ws/install/setup.bash ] && source ~/ws/install/setup.bash' >> ~/.bashrc
# ROS_DOMAIN_ID is deliberately NOT set here: your old template baked a
# build-time shuf result into the image (one "random" ID shared by every
# container). It is set per-container in run.sh instead.

CMD ["bash"]

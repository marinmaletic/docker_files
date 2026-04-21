FROM nvidia/cuda:12.6.1-cudnn-devel-ubuntu24.04

# ── Locale & env ──────────────────────────────────────────────────────────────
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV ROS2_DISTRO=jazzy
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute
ENV TZ=Europe/Zagreb
ENV DEBIAN_FRONTEND=noninteractive
ARG HOME=/root
ARG USERNAME=root

RUN apt-get update && apt-get install -y \
    software-properties-common lsb-release gnupg2 \
    && add-apt-repository universe \
    && apt-get update && apt-get install -y \
    # Build tools
    build-essential clang cmake ninja-build \
    cppcheck gdb valgrind ccache \
    # Version control & network
    git git-lfs curl wget \
    openssh-client \
    net-tools iputils-ping \
    # Python base (colcon & empy come from ROS2 repo, added below)
    python3 python3-pip python3-venv \
    python3-dev python3-setuptools python3-wheel \
    python-is-python3 \
    # Terminal utilities
    vim nano tmux tmuxinator \
    htop ranger tree \
    zip unzip jq \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ── Python linting / testing ──────────────────────────────────────────────────
RUN apt-get update && apt-get install -y \
    python3-flake8 \
    python3-flake8-blind-except \
    python3-flake8-builtins \
    python3-flake8-class-newline \
    python3-flake8-comprehensions \
    python3-flake8-deprecated \
    python3-flake8-docstrings \
    python3-flake8-import-order \
    python3-flake8-quotes \
    python3-pytest \
    python3-pytest-cov \
    python3-pytest-repeat \
    python3-pytest-rerunfailures \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ── SSH known hosts (build-time) ──────────────────────────────────────────────
# Allows --ssh default during build for private repo cloning
ENV DOCKER_BUILDKIT=1
ENV GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no"

RUN --mount=type=ssh \
    mkdir -p ~/.ssh && \
    ssh-keyscan -H github.com    >> ~/.ssh/known_hosts && \
    ssh-keyscan -H gitlab.com    >> ~/.ssh/known_hosts && \
    ssh-keyscan -H bitbucket.org >> ~/.ssh/known_hosts

# ── Locale ────────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y locales \
    && locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ── ROS2 apt source ───────────────────────────────────────────────────────────
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
        -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
        http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" \
        | tee /etc/apt/sources.list.d/ros2.list > /dev/null

# ── ROS2 Jazzy + colcon/empy (from ROS2 repo) ────────────────────────────────
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    ros-${ROS2_DISTRO}-desktop \
    ros-dev-tools \
    python3-rosdep \
    python3-colcon-common-extensions \
    python3-empy \
    python3-argcomplete \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ── Useful ROS2 packages ──────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y \
    ros-${ROS2_DISTRO}-tf-transformations \
    ros-${ROS2_DISTRO}-tf2-tools \
    ros-${ROS2_DISTRO}-nav2-bringup \
    ros-${ROS2_DISTRO}-nav2-map-server \
    ros-${ROS2_DISTRO}-nav2-lifecycle-manager \
    ros-${ROS2_DISTRO}-rosbridge-suite \
    ros-${ROS2_DISTRO}-rosbag2-storage-mcap \
    ros-${ROS2_DISTRO}-foxglove-bridge \
    ros-${ROS2_DISTRO}-xacro \
    ros-${ROS2_DISTRO}-robot-state-publisher \
    ros-${ROS2_DISTRO}-joint-state-publisher \
    ros-${ROS2_DISTRO}-joint-state-publisher-gui \
    ros-${ROS2_DISTRO}-rviz2 \
    ros-${ROS2_DISTRO}-teleop-twist-keyboard \
    ros-${ROS2_DISTRO}-teleop-twist-joy \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ── rosdep init ───────────────────────────────────────────────────────────────
RUN rosdep init && rosdep update

# ── Python packages ───────────────────────────────────────────────────────────
RUN PYTHON_VERSION=$(python --version | cut -d" " -f2 | cut -d"." -f1,2) && \
    rm -rf /usr/lib/python${PYTHON_VERSION}/EXTERNALLY-MANAGED

RUN pip install --break-system-packages \
    numpy scipy matplotlib \
    transforms3d \
    rowan \
    opencv-python \
    PyYAML \
    lark

# ── X11 / Qt dependencies ─────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y \
    libfontconfig1-dev libfreetype-dev \
    libx11-dev libx11-xcb-dev \
    libxcb-cursor-dev libxcb-glx0-dev \
    libxcb-icccm4-dev libxcb-image0-dev \
    libxcb-keysyms1-dev libxcb-randr0-dev \
    libxcb-render-util0-dev libxcb-shape0-dev \
    libxcb-shm0-dev libxcb-sync-dev \
    libxcb-util-dev libxcb-xfixes0-dev \
    libxcb-xinerama0-dev libxcb-xkb-dev \
    libxcb1-dev libxext-dev libxfixes-dev \
    libxi-dev libxkbcommon-dev libxkbcommon-x11-dev \
    libxrender-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ── Dotfiles & shell config ───────────────────────────────────────────────────
COPY config/aliases      /root/.bash_aliases
COPY config/tmux.conf    /root/.tmux.conf
COPY config/nanorc       /root/.nanorc

# ── Bashrc setup ──────────────────────────────────────────────────────────────
RUN echo "" >> $HOME/.bashrc && \
    echo "# ── ROS2 ────────────────────────────────────────────────" >> $HOME/.bashrc && \
    echo "source /opt/ros/${ROS2_DISTRO}/setup.bash" >> $HOME/.bashrc && \
    echo "" >> $HOME/.bashrc && \
    echo "# Workspace auto-source (if built)" >> $HOME/.bashrc && \
    echo "[ -f \$HOME/ros2_ws/install/setup.bash ] && source \$HOME/ros2_ws/install/setup.bash" >> $HOME/.bashrc && \
    echo "" >> $HOME/.bashrc && \
    echo "# ROS_DOMAIN_ID — change if multiple people share the same network" >> $HOME/.bashrc && \
    echo "export ROS_DOMAIN_ID=$(shuf -i 1-101 -n 1)" >> $HOME/.bashrc && \
    echo "" >> $HOME/.bashrc && \
    echo "export PATH=\$HOME/.local/bin:\$PATH" >> $HOME/.bashrc && \
    echo "" >> $HOME/.bashrc && \
    echo "# SSH agent socket (forwarded from host by first_run.sh)" >> $HOME/.bashrc && \
    echo "export SSH_AUTH_SOCK=/ssh-agent" >> $HOME/.bashrc

# ── ROS2 workspace scaffold ───────────────────────────────────────────────────
RUN mkdir -p $HOME/ros2_ws/src

WORKDIR $HOME/ros2_ws

RUN bash -c "\
    source /opt/ros/${ROS2_DISTRO}/setup.bash && \
    colcon build \
        --symlink-install \
        --merge-install \
        --cmake-args -DCMAKE_EXPORT_COMPILE_COMMANDS=ON"

# ── User groups (USB / serial devices) ───────────────────────────────────────
RUN usermod -a -G plugdev $USERNAME && \
    usermod -a -G dialout $USERNAME

WORKDIR $HOME
CMD ["/bin/bash"]
# docker_files

A collection of Docker environments for robotics and ML development. Each subfolder in `envs/` is a self-contained setup with its own `Dockerfile` and settings.

Your code stays in a separate git repo on the host and is mounted into the container, so containers hold no work and can be deleted freely.

## Available environments

| Folder | Base | Description | Container prefix |
|--------|------|-------------|------------------|
| `ubuntu24.04-jazzy-cuda12.6` | Ubuntu 24.04 + CUDA 12.6 | ROS2 Jazzy + MoveIt2 dev environment | `ros2_` |
| `ubuntu24.04-cuda12.6` | Ubuntu 24.04 + CUDA 12.6 | Plain CUDA / ML environment, no ROS | `dev_` |

---

## 1. [Install Docker](https://docs.docker.com/engine/install/ubuntu/)

```bash
# Run the following command to uninstall all conflicting packages:
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)

# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOD
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOD

sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Verify that the installation is successful by running the hello-world image:
```bash
sudo docker run hello-world
```

### Run Docker without sudo (recommended)
```bash
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker   # apply without logging out
```

### NVIDIA GPU support
```bash
# Install the NVIDIA Container Toolkit
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
  sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt update
sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Verify
docker run --rm --gpus all ubuntu nvidia-smi
```

If that fails with `Failed to initialize NVML`, create the device symlinks and retry:
```bash
sudo nvidia-ctk system create-dev-char-symlinks --create-all
```

---

## 2. Clone this repository

```bash
git clone git@github.com:marinmaletic/docker_files.git ~/docker_files
cd ~/docker_files
chmod +x scripts/*.sh
```

---

## 3. Allow GUI apps from Docker

```bash
xhost +local:docker

# Make it permanent
echo "xhost +local:docker > /dev/null" >> ~/.profile
```

---

## 4. SSH agent (for git push/pull inside containers)

The containers forward your host SSH agent, so no keys are stored inside Docker. Before creating any container, make sure your agent is running:

```bash
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_ed25519    # or id_rsa — whichever key you use for GitHub/GitLab
```

To avoid doing this on every login, add it to your `~/.profile`:
```bash
echo 'eval $(ssh-agent -s) > /dev/null && ssh-add ~/.ssh/id_ed25519 2>/dev/null' >> ~/.profile
```

---

## 5. Build an image

```bash
./scripts/build.sh                                # list available environments
./scripts/build.sh ubuntu24.04-jazzy-cuda12.6     # build one
```

---

## 6. Create a project

Each project is its own git repo, anywhere on the host. For ROS projects the repo root is the colcon workspace, so `src/` sits at the top.

```bash
mkdir -p ~/dev/ur10e/src
cd ~/dev/ur10e
git init
cp ~/docker_files/templates/gitignore .gitignore
```

Create the container (once):

```bash
~/docker_files/scripts/run.sh ~/dev/ur10e            # -> container ros2_ur10e
~/docker_files/scripts/run.sh ~/dev/ur10e arm_exp    # -> container ros2_arm_exp
```

For a project without ROS, copy `templates/container-env` into the project as `.container-env` and set `ENV_NAME=ubuntu24.04-cuda12.6` before running `run.sh`.

---

## 7. Daily use

```bash
# Open a terminal in the container (starts it if stopped)
~/docker_files/scripts/exec.sh ros2_ur10e

# List your containers
~/docker_files/scripts/exec.sh
```

In VS Code: **Dev Containers: Attach to Running Container**.

Inside the container, `~/ws` is your project repo on the host:

```bash
cd ~/ws
colcon build --symlink-install
source install/setup.bash
git commit -am "..." && git push
```

---

## 8. Adding dependencies

| Needed by | Put it in |
|---|---|
| One ROS package | that package's `package.xml`, then `rosdep install --from-paths src --ignore-src -y` |
| One project | `<project>/docker/Dockerfile` (copy from `templates/`), then `docker rm <container>` and `run.sh` again |
| Several projects | `envs/<environment>/Dockerfile`, then `build.sh` and recreate the containers |

After rebuilding an image, clear stale artifacts in each project: `rm -rf build install log`

---

## 9. Repository layout

```
docker_files/
├── envs/<ubuntu-ros-cuda version>/
│   ├── Dockerfile
│   ├── env.conf            image name, tag, container prefix, HAS_ROS
│   └── config/             environment-specific dotfiles
├── common/config/          dotfiles shared by all environments
├── scripts/
│   ├── build.sh            build an image
│   ├── run.sh              create a project container (once)
│   └── exec.sh             open a shell (daily)
└── templates/              gitignore, container-env, Dockerfile for projects
```

To add an environment, copy a folder in `envs/`, rename it after the versions it contains, and edit its `Dockerfile` and `env.conf`. The scripts pick it up automatically.

---

### Common Docker commands
```bash
# Re-enter a container directly
docker start -i <container_name>

# List all containers (running and stopped)
docker ps -a

# Stop / delete a container (safe — your code is on the host)
docker stop <container_name>
docker rm   <container_name>

# List / delete images
docker images
docker rmi <image_name>

# Reclaim disk space
docker system df
docker system prune --volumes
```

---

### Troubleshooting

**"cannot open display"** — run `xhost +local:docker`, then `exec.sh` again.

**RViz/Gazebo slow** — `glxinfo | grep -i "opengl renderer"` must name your GPU, not `llvmpipe`.

**`git push` can't reach the SSH agent** — restart it on the host, then `docker rm <container>` and `run.sh` again.

**`ros2: command not found` under `docker exec`** — non-interactive shells skip `.bashrc`; prepend `source /opt/ros/jazzy/setup.bash &&` to the command.

**"could not select device driver ... [[gpu]]"** — NVIDIA Container Toolkit missing or unregistered: reinstall it, run `sudo nvidia-ctk runtime configure --runtime=docker`, restart Docker.

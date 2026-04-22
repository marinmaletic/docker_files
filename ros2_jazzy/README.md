# ROS2 Jazzy — General Purpose Docker Container

A clean Docker environment for ROS2 Jazzy development on Ubuntu Noble 24.04.
Includes CUDA/GPU support, X11 forwarding, SSH agent forwarding for git, tmux, and a handy alias library.

---

## Prerequisites
- [Docker Engine](https://docs.docker.com/engine/install/ubuntu/) installed
- NVIDIA GPU (optional) — follow the [GPU support guide](https://github.com/larics/docker_files/wiki/2.-Installation#gpu-support) and install the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)


## Build & Run

```bash
# 1. Clone / copy this folder
cd ros2_jazzy

# 2. Export BuildKit (required for SSH during build)
export DOCKER_BUILDKIT=1

# 3. Build the image
docker build -t ros2_jazzy_img .

# 4. Start the SSH agent on your HOST (if not already running)
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_ed25519      # or id_rsa, whichever key you use for GitHub/GitLab

# 5. Create and enter the container for the first time
chmod +x first_run.sh && ./first_run.sh
```

### Subsequent runs
```bash
# Re-enter the container (attach to it)
docker start -i ros2_jazzy_cont

# Open a second terminal inside a running container
docker exec -it ros2_jazzy_cont bash

# Stop the container
docker stop ros2_jazzy_cont

# Delete the container (image stays)
docker rm ros2_jazzy_cont
```


## SSH & Git inside the container

The container mounts your host's SSH agent socket, so **no keys are stored inside the container**. As long as the agent is running on the host with your key loaded, you can do:

```bash
# Inside the container:
git clone git@github.com:yourname/your-repo.git
git push origin main
```

### Troubleshooting SSH
```bash
# Check if the agent is forwarded (inside container)
check_ssh_agent       # alias defined in config/aliases
ssh-add -l            # should list your key(s)

# If it shows "Could not open connection to authentication agent":
# → Make sure you ran `eval $(ssh-agent -s) && ssh-add` on the HOST before ./first_run.sh
# → Then recreate the container: docker rm ros2_jazzy_cont && ./first_run.sh
```

### Git config (do once inside the container)
```bash
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
```
These are saved in `/root/.gitconfig`. To persist across container recreations, mount a volume:
```bash
# Add to first_run.sh docker run:
--volume="$HOME/.gitconfig:/root/.gitconfig"
```

## Tmux & Tmuxinator

Start a pre-configured session:
```bash
./start.sh
```

### Tmux keybindings
| Keys | Action |
|------|--------|
| `Ctrl + ←/→/↑/↓` | Navigate panes |
| `Shift + ←/→` | Switch windows |
| `Ctrl+b  \|` | Split vertical |
| `Ctrl+b  -` | Split horizontal |
| `Ctrl+b  s` | Toggle sync panes |
| `Ctrl+b  k` | Kill all panes |
| `Ctrl+b  r` | Reload tmux.conf |
| Mouse | Click pane, scroll, resize |


## Useful Aliases (quick reference)

```bash
# ROS2
sr          # source /opt/ros/jazzy/setup.bash
sw          # source workspace
srw         # source both
cb          # colcon build (full)
cbt <pkg>   # colcon build single package
rtl         # ros2 topic list
rte <topic> # ros2 topic echo
rnl         # ros2 node list
tf-tree     # view TF tree (saved to frames.pdf)
kill_ros2   # kill all ROS2 processes
waitForRos2 # block until a node appears

# Git
gs / ga / gc / gp / gl / glog

# SSH
check_ssh_agent   # verify key forwarding
```

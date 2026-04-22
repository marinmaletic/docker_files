# docker_files
 
A collection of Docker environments for robotics development. Each subfolder is a self-contained setup with its own `Dockerfile`, run scripts, and config.
 
## Available environments
 
| Folder | Base | Description |
|--------|------|-------------|
| `ros2-jazzy` | Ubuntu 24.04 + CUDA 12.6.1 | General-purpose ROS2 Jazzy dev environment |
 
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
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Verify that the installation is successful by running the hello-world image:
``` bash
 sudo docker run hello-world
 ```

### Run Docker without sudo (recommended)
```bash
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker   # apply without logging out
```
 
### NVIDIA GPU support (if you have an NVIDIA GPU)
```bash
# Install the NVIDIA Container Toolkit
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
  sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
 
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
 
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```
 
---
 
## 2. Clone this repository
 
```bash
git clone git@github.com:marinmaletic/docker_files.git
cd docker_files
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
 
The containers in this repo forward your host SSH agent, so no keys are stored inside Docker. Before building or running any container, make sure your agent is running:
 
```bash
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_ed25519    # or id_rsa — whichever key you use for GitHub/GitLab
```
 
To avoid doing this on every login, add it to your `~/.profile`:
```bash
echo 'eval $(ssh-agent -s) > /dev/null && ssh-add ~/.ssh/id_ed25519 2>/dev/null' >> ~/.profile
```
 
---
 
## 5. Build & run an environment
 
Navigate to the environment you want and follow the `README.md` inside it. The general workflow is the same for all of them:
 
```bash
cd ros2-jazzy
 
export DOCKER_BUILDKIT=1
docker build -t <image_name> .
./first_run.sh
```

--- 

### Common Docker commands
```bash
# Re-enter a container after it has been stopped
docker start -i <container_name>
 
# Open another terminal in a running container
docker exec -it <container_name> bash
 
# List all containers (running and stopped)
docker ps -a
 
# Stop / delete a container
docker stop <container_name>
docker rm   <container_name>
 
# List images
docker images
 
# Delete an image
docker rmi <image_name>

# The docker system prune command is a shortcut that prunes images, containers, and networks. Volumes aren't pruned by default, and you must specify the --volumes flag for docker system prune to prune volumes.
docker system prune --volumes
```
 
# <project>/docker/Dockerfile — OPTIONAL. Only create this when the project
# needs packages that don't belong in the shared base image.
# run.sh detects it automatically and builds ros2-<project>:local.
#
# Prefer declaring ROS dependencies in each package's package.xml and
# running `rosdep install --from-paths src --ignore-src -y` in the container.
# Use this file for non-ROS system deps, or heavy pinned things like torch.

ARG BASE_IMAGE=ros2-jazzy-cuda:u2404-cu126
FROM ${BASE_IMAGE}

ARG USERNAME=marin
USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-jazzy-ur-robot-driver \
    && rm -rf /var/lib/apt/lists/*

USER ${USERNAME}

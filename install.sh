#!/bin/bash

#Stopped script when pipeline failed 
set -euo pipefail

#Sourcing ros2
if [ -f /opt/ros/humble/setup.bash ]; then
  set +u
  source /opt/ros/humble/setup.bash
  set -u
fi

#Find env.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$(ls "$SCRIPT_DIR" | grep -E '.*jmh\.sh$' | head -n 1 || true)"

if [ -z "${ENV_FILE:-}" ]; then
  echo "No *jmh.sh file found in $(basename "$SCRIPT_DIR")"
  exit 1
fi

#Copy env.sh
mkdir -p "$HOME/ros2_env"
cp "$SCRIPT_DIR/$ENV_FILE" "$HOME/ros2_env/"

#Select install sensor packages
echo ""
echo "Do you want to install and build sensor packages (Ouster, FLIR, MicroStrain)?"
read -rp "(y/n): " INSTALL_SENSORS
echo ""

ROS2_WS_ROOT="$HOME/ROS2/sensor_ws"
ROS2_WS_SRC="$ROS2_WS_ROOT/src"
ENV_PATH_LINE="source ~/ROS2/sensor_ws/install/setup.bash"

if [[ "$INSTALL_SENSORS" =~ ^[Yy]$ ]]; then
  mkdir -p "$ROS2_WS_SRC"

  
  if ! grep -Fxq "$ENV_PATH_LINE" "$HOME/ros2_env/$ENV_FILE"; then
    echo "$ENV_PATH_LINE" >> "$HOME/ros2_env/$ENV_FILE"
    echo "🔗 Added ROS2 workspace setup line to $HOME/ros2_env/$ENV_FILE"
  fi

  # Keep rosdep up-to-date
  rosdep update || true

  #Ouster sensor packages
  echo ""
  echo "Install and build Ouster packages?"
  read -rp "(y/n): " INSTALL_OUSTER
  echo ""

  if [[ "$INSTALL_OUSTER" =~ ^[Yy]$ ]]; then
    if [ ! -d "$ROS2_WS_SRC/ouster-ros" ]; then
      git -C "$ROS2_WS_SRC" clone -b ros2 --recurse-submodules https://github.com/ouster-lidar/ouster-ros.git
    fi
    pushd "$ROS2_WS_ROOT" >/dev/null
    rosdep install --from-paths ./src/ouster-ros/ -y --ignore-src
    colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release --packages-select ouster_ros ouster_sensor_msgs
    popd >/dev/null
  fi

  #Flir sensor packages
  echo ""
  echo "Install and build Flir packages?"
  read -rp "(y/n): " INSTALL_FLIR
  echo ""

  if [[ "$INSTALL_FLIR" =~ ^[Yy]$ ]]; then
    if [ ! -d "$ROS2_WS_SRC/flir_camera_driver" ]; then
      git -C "$ROS2_WS_SRC" clone --branch humble-devel https://github.com/ros-drivers/flir_camera_driver
    fi
    pushd "$ROS2_WS_ROOT" >/dev/null
    rosdep install --from-paths ./src/flir_camera_driver/ --ignore-src
    colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_EXPORT_COMPILE_COMMANDS=ON --packages-select spinnaker_camera_driver spinnaker_synchronized_camera_driver flir_camera_msgs flir_camera_description
    popd >/dev/null
  fi

  #Microstrain sensor packages
  echo ""
  echo "Install and build Flir packages?"
  read -rp "(y/n): " INSTALL_MICROSTRAIN
  echo ""

  if [[ "$INSTALL_MICROSTRAIN" =~ ^[Yy]$ ]]; then
    if [ ! -d "$ROS2_WS_SRC/microstrain_inertial" ]; then
      git -C "$ROS2_WS_SRC" clone --recursive --branch ros2 https://github.com/LORD-MicroStrain/microstrain_inertial.git ~/your_workspace/src/microstrain_inertial
    fi
    pushd "$ROS2_WS_ROOT" >/dev/null
    rosdep install --from-paths ./src/microstrain_inertial/ -i -r -y
    colcon build --packages-select microstrain_inertial_driver microstrain_inertial_msgs microstrain_inretial_examples microstrain_inertial_rqt microstrain_inertial_description
    popd >/dev/null
  fi

else
  if grep -Fxq "$ENV_PATH_LINE" "$HOME/ros2_env/$ENV_FILE"; then
    grep -Fxv "$ENV_PATH_LINE" "$HOME/ros2_env/$ENV_FILE" > "$HOME/ros2_env/${ENV_FILE}.tmp" && mv "$HOME/ros2_env/${ENV_FILE}.tmp" "$HOME/ros2_env/$ENV_FILE"
    echo "Removed: $ENV_PATH_LINE from $ENV_FILE"
  fi
fi

#Connect to .bashrc
if ! grep -q "source ~/ros2_env/${ENV_FILE}" "$HOME/.bashrc"; then
  echo "[ -f ~/ros2_env/${ENV_FILE} ] && source ~/ros2_env/${ENV_FILE}" >> "$HOME/.bashrc"
  echo "Added source line to ~/.bashrc"
else
  echo "~/.bashrc already sources ${ENV_FILE}"
fi

#Restart terminal
echo "Custom environment (${ENV_FILE}) installed."
echo "Restart terminal to apply."

#Remove install.sh
#echo "Removing installer: $0"
#rm -- "$0"
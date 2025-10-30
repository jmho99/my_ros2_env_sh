#ROS2 setting
source /opt/ros/humble/setup.bash
source ~/ROS2/sensor_ws/install/setup.bash
echo "complete sourcing ros2"
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
echo $RMW_IMPLEMENTATION
cat /proc/sys/net/core/rmem_max
cat /proc/sys/net/core/rmem_default

#ROS2 command
alias cm='ros2 launch spinnaker_camera_driver driver_node.launch.py'
alias ld='ros2 launch ouster_ros sensor.launch.xml'
alias sb='source install/setup.bash'
alias bf='sudo sysctl -w net.core.rmem_max=10485760 && sudo sysctl -w net.core.rmem_default=10485760 && sudo sysctl -w net.ipv4.tcp_rmem="4096 87380 10485760"'

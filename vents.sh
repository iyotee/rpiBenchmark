#!/bin/bash

# Get the fan speed
fan_speed=$(cat /sys/class/thermal/thermal_zone0/temp)

# Print the fan speed in RPM (you may need to adjust the conversion factor)
echo "Fan Speed: $((fan_speed / 1000)) RPM"

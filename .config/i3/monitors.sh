#!/bin/bash

# Get connected monitors
MONITORS=($(xrandr --query | grep " connected" | cut -d" " -f1))

if [ ${#MONITORS[@]} -eq 2 ]; then
  # Two monitors: place second to the right of the first
  xrandr --output "${MONITORS[1]}" --primary --auto \
    --output "${MONITORS[0]}" --auto --right-of "${MONITORS[1]}"
elif [ ${#MONITORS[@]} -eq 1 ]; then
  # Single monitor
  xrandr --output "${MONITORS[0]}" --primary --auto
fi

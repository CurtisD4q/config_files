#!/usr/bin/env sh
ws=$1
# Check if focused window is in the scratchpad
in_scratch=$(swaymsg -t get_tree | jq '.. | objects | select(.name=="__i3_scratch") | .focus | length')

if [ "$in_scratch" -gt 0 ]; then
  swaymsg floating disable
fi

swaymsg "move container to workspace number $ws"

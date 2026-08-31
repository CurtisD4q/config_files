#!/bin/bash

TMPDIR=$(mktemp -d /tmp/sway-overview.XXXXXX)
trap 'rm -rf "$TMPDIR"' EXIT

CURRENT=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused == true) | .name')
WORKSPACES=$(swaymsg -t get_workspaces | jq -r '.[].name')

for ws in $WORKSPACES; do
  swaymsg workspace "$ws"
  sleep 0.2
  OUTPUT=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused == true) | .name')
  grim -o "$OUTPUT" "$TMPDIR/$ws.png"
done

swaymsg workspace "$CURRENT"
swaymsg fullscreen enable
imv -f "$TMPDIR"/*.png
swaymsg fullscreen disable

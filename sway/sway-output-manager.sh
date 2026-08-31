#!/usr/bin/env sh
# sway-output-manager.sh — replaces kanshi for a laptop + one external setup.
# Watches output hotplug events and applies a layout automatically:
#
#   docked (external present): external at 0,0, laptop to its right
#   mobile (external absent):  laptop only
#
# The external is matched as "not the internal panel", so it works whatever it's
# called. The laptop's x-offset is the external's real width read live, so it
# adapts to differently sized monitors.
#
# Requires: swaymsg, jq.  Enable with:  exec ~/.config/sway/sway-output-manager.sh

INTERNAL="eDP-1"

apply_layout() {
  # Name of the first non-internal connected output (empty if none).
  name=$(swaymsg -t get_outputs |
    jq -r --arg int "$INTERNAL" \
      'first(.[] | select(.name != $int) | .name) // empty')

  if [ -n "$name" ]; then
    # Its width, as a separate query so a missing value can't corrupt name.
    # Try current_mode.width, then rect.width, then fall back to 1920.
    width=$(swaymsg -t get_outputs |
      jq -r --arg n "$name" \
        'first(.[] | select(.name == $n)
                     | (.current_mode.width // .rect.width // 1920))')
    # Guard: if width came back empty or non-numeric, default it.
    case "$width" in
    '' | *[!0-9]*) width=1920 ;;
    esac
    swaymsg output "$name" enable position 0 0
    swaymsg output "$INTERNAL" enable position "$width" 0
  else
    swaymsg output "$INTERNAL" enable position 0 0
  fi
}

apply_layout
swaymsg -t subscribe -m '["output"]' | while read -r _; do
  sleep 0.5
  apply_layout
done

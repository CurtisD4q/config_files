#!/usr/bin/env sh
killall -q waybar
while pgrep -x waybar >/dev/null; do sleep 0.1; done

waybar &

# apply effects once now, then again on every output change (hotplug)
~/.config/sway/waybar-effects.sh &
swaymsg -t subscribe -m '["output"]' | while read -r _; do
  sleep 1
  ~/.config/sway/waybar-effects.sh
done &

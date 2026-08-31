#!/usr/bin/env sh
# sway-fullscreen-confine.sh
#
# Confines the cursor to a fullscreen app's monitor by DISABLING the other
# outputs while any window is fullscreen, then re-enabling them when fullscreen
# ends. This is the approach that reliably works from a script on Wayland/Sway:
# rather than trying to trap the pointer (which Wayland reserves for the app
# itself), we simply remove the monitors it could escape to, so it has nowhere
# to go. When you leave fullscreen, your other monitors come back.
#
# Trade-off: your other monitors go black while you're in a fullscreen app.
# For gaming that's usually fine (you're not looking at them anyway). If you
# want the OTHER approach (true pointer confinement), that needs a dedicated
# Wayland pointer-constraints tool, which is finicky — this is the robust route.
#
# Requires: swaymsg, jq
# Enable by adding to ~/.config/sway/config:
#     exec ~/.config/sway/sway-fullscreen-confine.sh

STATE_FILE="/tmp/sway-confine-disabled-outputs"

on_fullscreen() {
  focused_output="$1"
  : >"$STATE_FILE"
  # disable every ENABLED output that is NOT the fullscreen one; remember them
  swaymsg -t get_outputs | jq -r '.[] | select(.active==true) | .name' |
    while read -r out; do
      [ "$out" = "$focused_output" ] && continue
      echo "$out" >>"$STATE_FILE"
      swaymsg output "$out" disable
    done
}

on_unfullscreen() {
  [ -f "$STATE_FILE" ] || return 0
  while read -r out; do
    [ -n "$out" ] && swaymsg output "$out" enable
  done <"$STATE_FILE"
  rm -f "$STATE_FILE"
}

swaymsg -t subscribe -m '["window"]' | while read -r line; do
  change=$(printf '%s' "$line" | jq -r '.change // empty')
  [ "$change" = "fullscreen_mode" ] || continue

  fs=$(printf '%s' "$line" | jq -r '.container.fullscreen_mode // 0')
  if [ "$fs" != "0" ]; then
    focused_output=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused==true) | .name')
    on_fullscreen "$focused_output"
  else
    on_unfullscreen
  fi
done

#!/usr/bin/env sh
INTERNAL="eDP-1"
STATE=/tmp/sway-external-off

if [ -f "$STATE" ]; then
  while read -r out; do
    [ -n "$out" ] && swaymsg output "$out" enable
  done <"$STATE"
  rm -f "$STATE"
else
  : >"$STATE"
  swaymsg -t get_outputs | jq -r --arg int "$INTERNAL" \
    '.[] | select(.name != $int) | select(.active == true) | .name' |
    while read -r out; do
      echo "$out" >>"$STATE"
      swaymsg output "$out" disable
    done
fi

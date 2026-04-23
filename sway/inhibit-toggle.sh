#!/usr/bin/env sh

PIDFILE="$HOME/.config/sway/swayidle.pid"

if [ -f "$PIDFILE" ]; then
  # inhibit is active — restore swayidle
  kill "$(cat $PIDFILE)" 2>/dev/null
  rm -f "$PIDFILE"
  notify-send "Idle inhibitor OFF" "Screen will lock normally"
else
  # kill swayidle to prevent timeout
  pkill swayidle
  touch "$PIDFILE"
  notify-send "Idle inhibitor ON" "Screen will not lock"
fi

#!/usr/bin/env sh

PIDFILE="$HOME/.config/sway/swayidle.pid"

if [ -f "$PIDFILE" ]; then
  # Inhibit is active — restore your custom swayidle media wrapper
  kill "$(cat $PIDFILE)" 2>/dev/null
  rm -f "$PIDFILE"

  # Relaunch your specific media wrapper script cleanly in the background
  ~/.local/bin/swayidle-media-wrap >/dev/null 2>&1 &

  notify-send "Idle inhibitor OFF" "Screen will lock normally"
else
  # Kill both raw swayidle and your media wrapper script to inhibit locking
  pkill -f swayidle-media-wrap
  pkill swayidle

  # Save the wrapper script's background status or a placeholder dummy PID
  echo "$$" >"$PIDFILE"
  notify-send "Idle inhibitor ON" "Screen will not lock"
fi

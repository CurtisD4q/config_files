#!/usr/bin/env sh
notify-send "Locking screen..."
# Wrapper script called by swayidle — avoids quote-nesting issues
exec swaylock -f --image "/home/curtis/Pictures/wallpaper.png"

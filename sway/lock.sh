#!/usr/bin/env sh
notify-send "Locking screen..."
# Wrapper script called by swayidle — avoids quote-nesting issues
exec swaylock -f --image "$HOME/Downloads/screensaver3.jpg"

#!/bin/sh

# Define the options to display in Fuzzel
options="🔒 Lock\n🚪 Log Out\n💤 Suspend\n🔄 Reboot\n⏻ Shut Down"

# Launch fuzzel in dmenu mode and capture the selected option
chosen=$(printf "$options" | fuzzel --dmenu --prompt="⚡ Power Menu: " --width=20 --lines=5)

# Strip out emojis and convert to lowercase for easier string matching
action=$(echo "$chosen" | sed 's/[^a-zA-Z ]//g' | xargs | tr '[:upper:]' '[:lower:]')

# Handle the actions
case "$action" in
"lock")
  # Swap swaylock out for your preferred screen locker if needed
  /usr/local/bin/gtklock -d
  ;;
"log out")
  swaymsg exit
  ;;
"suspend")
  systemctl suspend
  ;;
"reboot")
  systemctl reboot
  ;;
"shut down")
  systemctl poweroff
  ;;
*)
  exit 0
  ;;
esac

#!/usr/bin/env bash
# i3bar protocol status script: wifi, bluetooth, battery, volume, cpu%, gpu%, clock
# Requirements: jq, swaymsg
# Optional: nmcli, bluetoothctl, upower, pactl, nvidia-smi

set -u

# Colors
COLOR_WIFI="9B30FF"
COLOR_BT="#9B30FF"
COLOR_BATT="#9B30FF"
COLOR_VOL="#9B30FF"
COLOR_CPU="#9B30FF"
COLOR_GPU="#9B30FF"
COLOR_CLOCK="#9B30FF"

# ----------------------
# Helpers
# ----------------------
get_active_tab() { echo ""; } # not used but keep for compatibility

wifi_status() {
  command -v nmcli >/dev/null || {
    echo "WiFi: n/a"
    return
  }
  local gstate active ssid sig
  gstate=$(nmcli -t -f WIFI g 2>/dev/null || echo "unknown")
  if [ "$gstate" != "enabled" ]; then
    echo "WiFi: off"
    return
  fi
  active=$(nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi 2>/dev/null | awk -F: '$1=="yes"{print $2 "|" $3; exit}')
  if [ -z "$active" ]; then
    echo "WiFi: disconnected"
  else
    ssid=${active%|*}
    sig=${active#*|}
    echo "${ssid} (${sig}%)"
  fi
}

bt_status() {
  command -v bluetoothctl >/dev/null || {
    echo "BT: n/a"
    return
  }
  local power conns
  power=$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered/ {print $2}' || echo "no")
  if [ "$power" != "yes" ]; then
    echo "BT: off"
    return
  fi
  conns=$(bluetoothctl devices | awk '{print $2}' | while read -r mac; do bluetoothctl info "$mac" 2>/dev/null | awk -F': ' '/Connected/ {print $2}'; done | grep -c yes || true)
  echo "BT: on (${conns} conn)"
}

battery_status() {
  # Try upower
  if command -v upower >/dev/null; then
    # find battery device
    dev=$(upower -e | grep battery | head -n1)
    if [ -n "$dev" ]; then
      perc=$(upower -i "$dev" 2>/dev/null | awk -F': ' '/percentage/ {print $2}' | tr -d '%')
      state=$(upower -i "$dev" 2>/dev/null | awk -F': ' '/state/ {print $2}' | tr -d ' ')
      echo "${perc}% (${state})"
      return
    fi
  fi
  # Fallback: sysfs
  if [ -f /sys/class/power_supply/BAT0/capacity ]; then
    perc=$(cat /sys/class/power_supply/BAT0/capacity)
    status=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo "N/A")
    echo "${perc}% (${status})"
    return
  fi
  echo "Battery: n/a"
}

volume_status() {
  # Use pactl to get default sink volume and mute state
  if command -v pactl >/dev/null; then
    sink=$(pactl info 2>/dev/null | awk -F': ' '/Default Sink/ {print $2}')
    if [ -z "$sink" ]; then
      echo "Vol: n/a"
      return
    fi
    # get volume and mute from sink info
    read -r vol mute <<<"$(pactl get-sink-volume "$sink" 2>/dev/null | awk '/Volume/ {print $5}' | sed 's/%//' || echo "n/a") $(pactl get-sink-mute "$sink" 2>/dev/null | awk -F': ' '/Mute/ {print $2}' || echo "no")"
    # The above parsing might vary; fallback to simpler method:
    if [ "$vol" = "n/a" ]; then
      vol=$(pactl list sinks | awk '/Volume: front/{print $5; exit}' | tr -d '%')
    fi
    if [ -z "$vol" ]; then echo "Vol: n/a"; else echo "Vol: ${vol}% (${mute})"; fi
    return
  fi
  echo "Vol: n/a"
}

cpu_usage() {
  # Read /proc/stat twice and calculate %
  if [ -r /proc/stat ]; then
    # sample 1
    read -r cpu a b c d e f g h i j </proc/stat
    prev_idle=$((d + f))
    prev_total=$((a + b + c + d + e + f + g + h + i + j))
    sleep 0.5
    read -r cpu a b c d e f g h i j </proc/stat
    idle=$((d + f))
    total=$((a + b + c + d + e + f + g + h + i + j))
    diff_idle=$((idle - prev_idle))
    diff_total=$((total - prev_total))
    if [ "$diff_total" -le 0 ]; then
      echo "CPU: n/a"
      return
    fi
    cpu_usage=$(((1000 * (diff_total - diff_idle) / diff_total + 5) / 10))
    echo "${cpu_usage}%"
    return
  fi
  echo "CPU: n/a"
}

gpu_usage() {
  # Try NVIDIA nvidia-smi
  if command -v nvidia-smi >/dev/null; then
    # get GPU utilization for first GPU
    util=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1)
    if [ -n "$util" ]; then
      echo "${util}%"
      return
    fi
  fi
  # AMD GPU support could be added (lspci / radeontop) — fallback:
  echo "GPU: n/a"
}

# ----------------------
# i3bar header
# ----------------------
echo '{"version":1}'
echo '['
echo '[],'

# ----------------------
# Emit status
# ----------------------
emit_status() {
  local timestr wifi bt batt vol cpu gpu out first
  timestr=$(date '+%Y-%m-%d %H:%M:%S')
  wifi=$(wifi_status)
  bt=$(bt_status)
  #batt=$(battery_status)
  batt_amnt=$(</sys/class/power_supply/BAT0/capacity)
  batt_status=$(</sys/class/power_supply/BAT0/status)
  vol=$(volume_status)
  cpu=$(cpu_usage)
  gpu=$(gpu_usage)

  out='['
  first=true

  # wifi
  out+='{"name":"wifi","full_text:":" '"$wifi"' ","color":"'"$COLOR_WIFI"'","instance":"wifi"}'
  first=false

  # bluetooth
  out+=','
  out+='{"name":"bluetooth","full_text":" '"$bt"' ","color":"'"$COLOR_BT"'","instance":"bluetooth"}'

  # battery
  out+=','
  out+='{"name":"battery","full_text":" '"Battery: $batt_amnt% ($batt_status)"' ","color":"'"$COLOR_BATT"'","instance":"battery"}'

  # volume
  out+=','
  out+='{"name":"volume","full_text":" '"$vol"' ","color":"'"$COLOR_VOL"'","instance":"volume"}'

  # cpu
  out+=','
  out+='{"name":"cpu","full_text":" CPU: '"$cpu"' ","color":"'"$COLOR_CPU"'","instance":"cpu"}'

  # gpu
  out+=','
  out+='{"name":"gpu","full_text":" GPU: '"$gpu"' ","color":"'"$COLOR_GPU"'","instance":"gpu"}'

  # clock
  out+=','
  out+='{"name":"clock","full_text":" '"$(date +'%d-%m-%y  %H:%M')"' ","color":"'"$COLOR_CLOCK"'","instance":"clock"}'

  out+=']'
  echo "$out,"
}

# ----------------------
# Click handling (basic)
# ----------------------
handle_clicks() {
  while read -r line; do
    name=$(jq -r '.name // empty' <<<"$line" 2>/dev/null || echo "")
    button=$(jq -r '.button // empty' <<<"$line" 2>/dev/null || echo "")
    [ -z "$name" ] && continue

    # Left click toggles useful things
    if [ "$button" = "1" ]; then
      if [ "$name" = "wifi" ] && command -v nmcli >/dev/null; then
        if [ "$(nmcli -t -f WIFI g 2>/dev/null)" = "enabled" ]; then nmcli radio wifi off & else nmcli radio wifi on & fi
        continue
      fi
      if [ "$name" = "bluetooth" ] && command -v bluetoothctl >/dev/null; then
        if bluetoothctl show 2>/dev/null | awk -F': ' '/Powered/ {print $2}' | grep -q yes; then bluetoothctl power off >/dev/null 2>&1 & else bluetoothctl power on >/dev/null 2>&1 & fi
        continue
      fi
      if [ "$name" = "volume" ] && command -v pactl >/dev/null; then
        # toggle mute on default sink
        sink=$(pactl info 2>/dev/null | awk -F': ' '/Default Sink/ {print $2}')
        [ -n "$sink" ] && pactl set-sink-mute "$sink" toggle
        continue
      fi
      if [ "$name" = "battery" ]; then
        # open a terminal with upower info if available
        if command -v alacritty >/dev/null && command -v upower >/dev/null; then
          alacritty -e sh -c 'upower -i $(upower -e | grep battery | head -n1); read -n1 -r -p "Press any key..."' >/dev/null 2>&1 &
        fi
        continue
      fi
      if [ "$name" = "cpu" ]; then
        # open htop if available
        if command -v alacritty >/dev/null && command -v htop >/dev/null; then
          alacritty -e htop >/dev/null 2>&1 &
        fi
        continue
      fi
      if [ "$name" = "gpu" ]; then
        if command -v nvidia-smi >/dev/null; then
          if command -v alacritty >/dev/null; then
            alacritty -e nvidia-smi -l 1 >/dev/null 2>&1 &
          fi
        fi
        continue
      fi
      if [ "$name" = "clock" ]; then
        if command -v alacritty >/dev/null; then
          alacritty -e sh -c 'cal -y; read -n1 -r -p "Press any key..."' >/dev/null 2>&1 &
        fi
        continue
      fi
    fi

    # Right-click (3): open settings where applicable
    if [ "$button" = "3" ]; then
      if [ "$name" = "wifi" ] && command -v nm-connection-editor >/dev/null; then
        nm-connection-editor >/dev/null 2>&1 &
        continue
      fi
      if [ "$name" = "bluetooth" ] && command -v alacritty >/dev/null; then
        alacritty -e bluetoothctl >/dev/null 2>&1 &
        continue
      fi
    fi
  done
}

# ----------------------
# Start click handler and forward stdin
# ----------------------
FIFO="/tmp/sway_status_click_fifo_$$"
trap 'rm -f "$FIFO"; exit' INT TERM EXIT
mkfifo "$FIFO"
handle_clicks <"$FIFO" &
CLICK_PID=$!
cat -u >"$FIFO" &
FORWARD_PID=$!

# ----------------------
# Main loop
# ----------------------
while true; do
  emit_status
  sleep 1
done

# cleanup
kill "$CLICK_PID" "$FORWARD_PID" 2>/dev/null || true
rm -f "$FIFO"

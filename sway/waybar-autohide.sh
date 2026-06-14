#!/usr/bin/env sh

cleanup() {
  rm -f /tmp/waybar_hidden_bar-*
  exit
}
trap cleanup INT TERM

get_focused_output() {
  swaymsg -t get_outputs | python3 -c "
import json, sys
for i, o in enumerate(json.load(sys.stdin)):
    if o.get('focused') and o.get('active'):
        print(i, o['name'])
        break
"
}

is_fullscreen() {
  local output_name="$1"
  swaymsg -t get_tree | python3 -c "
import json, sys
def find_output(node, name):
    if node.get('type') == 'output' and node.get('name') == name:
        return node
    for child in node.get('nodes', []) + node.get('floating_nodes', []):
        r = find_output(child, name)
        if r: return r
def find_fullscreen(node):
    if node.get('fullscreen_mode', 0) == 1:
        return True
    return any(find_fullscreen(c) for c in node.get('nodes', []) + node.get('floating_nodes', []))
out = find_output(json.load(sys.stdin), '$output_name')
print('yes' if out and find_fullscreen(out) else 'no')
"
}

rm -f /tmp/waybar_hidden_bar-*

while true; do
  read -r BAR_INDEX FOCUSED_OUTPUT <<EOF
$(get_focused_output)
EOF

  FULLSCREEN=$(is_fullscreen "$FOCUSED_OUTPUT")
  HIDDEN_FILE="/tmp/waybar_hidden_bar-$BAR_INDEX"

  if [ "$FULLSCREEN" = "yes" ] && [ ! -f "$HIDDEN_FILE" ]; then
    pkill -SIGUSR1 -f "waybar -b bar-$BAR_INDEX"
    touch "$HIDDEN_FILE"
  elif [ "$FULLSCREEN" = "no" ] && [ -f "$HIDDEN_FILE" ]; then
    pkill -SIGUSR1 -f "waybar -b bar-$BAR_INDEX"
    rm -f "$HIDDEN_FILE"
  fi

  # Restore bars on non-focused monitors
  for hidden in /tmp/waybar_hidden_bar-*; do
    [ -f "$hidden" ] || continue
    INDEX="${hidden##*/tmp/waybar_hidden_bar-}"
    if [ "$INDEX" != "$BAR_INDEX" ]; then
      pkill -SIGUSR1 -f "waybar -b bar-$INDEX"
      rm -f "$hidden"
    fi
  done

  sleep 1
done

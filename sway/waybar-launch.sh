#!/usr/bin/env sh

killall waybar 2>/dev/null
sleep 0.5

swaymsg -t get_outputs | python3 -c "
import json, sys
outputs = json.load(sys.stdin)
for i, o in enumerate(outputs):
    if o.get('active'):
        print(i, o.get('name'))
" >/tmp/waybar_outputs

while read -r index name; do
  python3 -c "
import json, re, sys

with open('/home/$USER/.config/waybar/config') as f:
    content = f.read()

# Strip single line comments
content = re.sub(r'//[^\n]*', '', content)
# Strip multi line comments
content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)

config = json.loads(content)
config['output'] = '$name'

with open('/tmp/waybar-config-$name', 'w') as f:
    json.dump(config, f, indent=2)
"
  waybar -b "bar-$index" -c "/tmp/waybar-config-$name" &
done </tmp/waybar_outputs

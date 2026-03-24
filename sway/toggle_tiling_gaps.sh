#!/usr/bin/env sh
# get active workspace id
ws=$(swaymsg -t get_workspaces | jq '.[] | select(.focused==true).id')
# get layout of focused container (root of workspace)
layout=$(swaymsg -t get_tree | jq -r --argjson ws "$ws" '
  def find(n): (n.nodes[]?, n.floating_nodes[]?) | select(.type=="workspace" and .id==$ws) // (n.nodes[]? | find(.));
  find(.) | .layout // "splith"
')
# toggle between tabbed/stacked and default tiling
if [ "$layout" = "tabbed" ] || [ "$layout" = "stacked" ]; then
  swaymsg layout default
  swaymsg gaps inner 10
  swaymsg gaps outer 13
else
  swaymsg layout toggle split
fi

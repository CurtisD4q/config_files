#!/usr/bin/env sh
total_file="/tmp/scratchpad_total"
index_file="/tmp/scratchpad_index"

get_hidden() {
  swaymsg -t get_tree | jq '.. | objects | select(.name=="__i3_scratch") | .floating_nodes | length'
}

get_stored() {
  cat "$total_file" 2>/dev/null || echo "0"
}

get_index() {
  cat "$index_file" 2>/dev/null || echo "1"
}

reset_state() {
  echo "0" >"$total_file"
  echo "1" >"$index_file"
}

update_total() {
  hidden=$1
  stored=$(get_stored)
  if [ "$hidden" -gt "$stored" ]; then
    echo "$hidden" >"$total_file"
    echo "1" >"$index_file"
  fi
}

next_window() {
  stored=$(get_stored)
  hidden=$(get_hidden)

  if [ "$hidden" -eq 0 ]; then
    # all windows visible, hide the current one
    swaymsg scratchpad show
  else
    index=$(get_index)
    next=$(((index % stored) + 1))
    echo "$next" >"$index_file"
    swaymsg scratchpad show
  fi
}

status() {
  hidden=$(get_hidden)

  if [ "$hidden" -eq 0 ]; then
    reset_state
    echo ""
    return
  fi

  update_total "$hidden"
  stored=$(get_stored)

  if [ "$hidden" -eq "$stored" ]; then
    echo "1" >"$index_file"
    echo "$stored"
  else
    index=$(get_index)
    echo "$index of $stored"
  fi
}

case "$1" in
next) next_window ;;
*) status ;;
esac

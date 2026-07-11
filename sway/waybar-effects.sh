#!/usr/bin/env sh
# Reapply Waybar layer effects whenever outputs change
swaymsg 'layer_effects "waybar" corner_radius 3'
swaymsg 'layer_effects "waybar" blur enable; shadows enable; shadow_blur_radius 20'

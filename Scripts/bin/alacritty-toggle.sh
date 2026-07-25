#!/usr/bin/env bash

# Detectar en qué monitor está el foco actual del mouse o ventana con bspc
focused_monitor=$(bspc query -M -m focused --names)

if [[ "$focused_monitor" == "HDMI-1" ]]; then
    alacritty --config-file ~/.config/alacritty/alacritty-tv.toml
else
    alacritty --config-file ~/.config/alacritty/alacritty-netbook.toml
fi

#!/usr/bin/env bash

# Matar instancias previas
killall -q polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Lanzar barras según el monitor detectado
if xrandr --query | grep -q "HDMI-1 connected"; then
    polybar --reload netbook &
    polybar --reload tv &
else
    polybar --reload netbook &
fi

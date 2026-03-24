#!/bin/bash

# Cantidad de paquetes actualizables
updates=$(apt list --upgradable 2>/dev/null | grep -v Listing | wc -l)

# Hora actual
time=$(date "+%H:%M")

if [ "$updates" -eq 0 ]; then
    # Estado normal → color base (cyan suave)
    echo "%{F#6f8f8f}$time%{F-}"
else
    # Estado alerta → rojo (rompe patrón visual)
    echo "%{F#a86c6c}$time%{F-}"
fi

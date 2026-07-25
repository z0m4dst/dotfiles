#!/bin/bash

# Cantidad de paquetes actualizables, ignorando los que contienen
updates=$(apt list --upgradable 2>/dev/null | grep -vE "Listing|Listando|grub|task|^$" | wc -l)
#61afef
# Hora actual
time=$(date "+%H:%M")

if [ "$updates" -eq 0 ]; then
    # Estado normal → color base (cyan suave)
    echo "%{F#61afef}$time%{F-}"
else
    # Estado alerta → rojo
    echo "%{F#a86c6c}$time%{F-}"
fi

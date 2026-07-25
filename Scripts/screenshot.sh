#!/bin/bash
# Directorio de guardado
DIR="/home/z0m4/Imágenes/Screenshots"
FILENAME="$DIR/screenshot_$(date +%Y%m%d_%H%M%S).png"

if [ "$1" == "full" ]; then
    # Captura toda la pantalla
    maim "$FILENAME"
else
    # Captura con selector (slop)
    maim -s "$FILENAME"
fi

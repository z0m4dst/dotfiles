#!/bin/bash

# Salir si hay errores
set -e

echo "[z0m4] Setup iniciado para Debian Nativo..."

# =========================
# REQUISITOS DEL SISTEMA
# =========================
echo "[+] Actualizando repositorios..."
sudo apt update && sudo apt upgrade -y

echo "[+] Instalando Xorg y dependencias base..."
# Instalamos el servidor gráfico, gestor de sesión (LightDM) y herramientas de compilación
sudo apt install -y xserver-xorg-core xserver-xorg x11-xserver-utils \
xinit lightdm lightdm-gtk-greeter build-essential libx11-dev libxft-dev \
libxinerama-dev libxrandr-dev

# =========================
# PAQUETES DEL ENTORNO
# =========================
echo "[+] Instalando paquetes desde pkglist.txt y extras..."
# Aseguramos que los paquetes base de tu dotfiles estén presentes
if [ -f pkglist.txt ]; then
    sudo xargs -a pkglist.txt apt install -y
else
    echo "[!] pkglist.txt no encontrado, instalando componentes críticos manualmente..."
    sudo apt install -y bspwm sxhkd polybar rofi alacritty picom thunar zsh feh
fi

# =========================
# CONFIGURACIONES (.config)
# =========================
echo "[+] Desplegando configuraciones..."
CONFIG_DIR="$HOME/.config"
mkdir -p "$CONFIG_DIR"

# Lista de carpetas a copiar
configs=("bspwm" "sxhkd" "polybar" "rofi" "alacritty" "picom" "gtk-3.0" "Thunar")

for folder in "${configs[@]}"; do
    if [ -d "config/$folder" ]; then
        cp -r "config/$folder" "$CONFIG_DIR/"
        echo "  -> $folder copiado."
    fi
done

# =========================
# HOME FILES & SCRIPTS
# =========================
echo "[+] Configurando archivos de usuario y scripts..."
cp home/.zshrc ~/ 2>/dev/null || echo "Aviso: .zshrc no encontrado"
cp home/.nanorc ~/ 2>/dev/null
cp home/.profile ~/ 2>/dev/null

mkdir -p ~/.local/bin
if [ -d "scripts" ]; then
    cp scripts/* ~/.local/bin/
    chmod +x ~/.local/bin/*
fi

# =========================
# ASSETS (Fuentes, Iconos, Walls)
# =========================
echo "[+] Instalando assets..."
mkdir -p ~/Img ~/.fonts ~/.icons

cp -r assets/wallpapers/* ~/Img/ 2>/dev/null
cp -r assets/fonts/* ~/.fonts/ 2>/dev/null
cp -r assets/icons/Papirus-Dark ~/.icons/ 2>/dev/null

# Refrescar caché de fuentes
fc-cache -fv > /dev/null

# =========================
# PERMISOS Y ARRANQUE
# =========================
echo "[+] Ajustando permisos de ejecución..."
chmod +x ~/.config/bspwm/bspwmrc
chmod +x ~/.config/sxhkd/sxhkdrc
[ -f ~/.config/polybar/launch.sh ] && chmod +x ~/.config/polybar/launch.sh

# Crear .xinitrc por si prefieres arrancar con 'startx'
echo "exec bspwm" > ~/.xinitrc

# Habilitar el gestor de login para que inicie al bootear
sudo systemctl enable lightdm

echo "---"
echo "[z0m4] Entorno listo. Reinicia para ver los cambios."

#!/bin/bash

echo "[z0m4] setup iniciado..."

# =========================
# UPDATE
# =========================

echo "[+] actualizando sistema..."
sudo apt update && sudo apt upgrade -y

# =========================
# PAQUETES
# =========================

echo "[+] instalando paquetes..."
sudo xargs -a pklist.txt apt install -y
# =========================
# CONFIGS
# =========================

echo "[+] copiando configuraciones..."

CONFIG_DIR="$HOME/.config"

mkdir -p "$CONFIG_DIR"

cp -r config/bspwm "$CONFIG_DIR/"
cp -r config/sxhkd "$CONFIG_DIR/"
cp -r config/polybar "$CONFIG_DIR/"
cp -r config/rofi "$CONFIG_DIR/"
cp -r config/alacritty "$CONFIG_DIR/"
cp -r config/picom "$CONFIG_DIR/"
cp -r config/gtk-3.0 "$CONFIG_DIR/"
cp -r config/Thunar "$CONFIG_DIR/" 2>/dev/null

# =========================
# HOME FILES
# =========================

echo "[+] copiando archivos de home..."

cp home/.zshrc ~/
cp home/.nanorc ~/
cp home/.gitconfig ~/ 2>/dev/null
cp home/.profile ~/

# =========================
# SCRIPTS
# =========================

echo "[+] instalando scripts..."

mkdir -p ~/.local/bin

cp scripts/* ~/.local/bin/
chmod +x ~/.local/bin/*

# =========================
# ASSETS
# =========================

echo "[+] copiando assets..."

mkdir -p ~/Img
cp -r assets/wallpapers/* ~/Img/ 2>/dev/null

mkdir -p ~/.fonts
cp -r assets/fonts/* ~/.fonts/ 2>/dev/null

mkdir -p ~/.icons
 cp -r assets/icons/Papirus-Dark ~/.icons 2>/dev/null
# =========================
# PERMISOS IMPORTANTES
# =========================

echo "[+] aplicando permisos..."

chmod +x ~/.config/bspwm/bspwmrc
chmod +x ~/.config/sxhkd/sxhkdrc
chmod +x ~/.config/polybar/launch.sh 2>/dev/null

# =========================
# FINAL
# =========================

echo "[z0m4] entorno listo"

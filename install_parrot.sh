#!/bin/bash

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR

LOG_FILE="/var/log/conversion_status.log"

# Intentar cargar los scripts base si existen (para las opciones de conversión)
[ -f "$SCRIPT_DIR/scripts/run.sh" ] && source "$SCRIPT_DIR/scripts/run.sh" || true
[ -f "$SCRIPT_DIR/scripts/check_sudo.sh" ] && source "$SCRIPT_DIR/scripts/check_sudo.sh" || true
[ -f "$SCRIPT_DIR/scripts/editions/core.sh" ] && source "$SCRIPT_DIR/scripts/editions/core.sh" || true
[ -f "$SCRIPT_DIR/scripts/editions/home.sh" ] && source "$SCRIPT_DIR/scripts/editions/home.sh" || true
[ -f "$SCRIPT_DIR/scripts/editions/security.sh" ] && source "$SCRIPT_DIR/scripts/editions/security.sh" || true
[ -f "$SCRIPT_DIR/scripts/editions/htb.sh" ] && source "$SCRIPT_DIR/scripts/editions/htb.sh" || true

# Asegurar privilegios root para instalar paquetes
if [ "$EUID" -ne 0 ]; then
    echo "[!] ERROR: Este script debe ejecutarse como root (sudo)."
    exit 1
fi

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_system() {
    log "Performing system checks..."
    if ! grep -q -E "Debian|Parrot" /etc/os-release; then
        log "ERROR: This script requires Debian or Parrot base"
        return 1
    fi
    log "System checks passed successfully"
    return 0
}

blindar_sistema() {
    log "[SEGURIDAD] Congelando paquetes del GRUB para blindar el arranque..."
    apt-mark hold grub-common grub-efi-amd64 grub-efi-amd64-bin grub-efi-amd64-signed || true
    
    log "[SEGURIDAD] Configurando APT para prevenir desinstalaciones cruzadas..."
    alias apt-get='apt-get --no-remove'
    alias apt='apt --no-remove'
    export -f log
}

# ==============================================================================
# FUNCIÓN DE DOTFILES Y ASSETS
# ==============================================================================
desplegar_entorno_nativo() {
    log "[z0m4-RICE] Iniciando despliegue de entorno gráfico y assets..."
    
    # Asegurar que las herramientas base de Xorg y compilación estén listas
    log "[+] Instalando Xorg y dependencias base..."
    apt-get install -y --no-remove xserver-xorg-core xserver-xorg x11-xserver-utils xinit build-essential libx11-dev libxft-dev libxinerama-dev libxrandr-dev

    # Instalar paquetes desde tu pkglist.txt filtrado
    if [ -f "$SCRIPT_DIR/pkglist.txt" ]; then
        log "[+] Instalando paquetes desde pkglist.txt..."
        xargs -a "$SCRIPT_DIR/pkglist.txt" apt-get install -y --no-remove || log "Aviso: Algunos paquetes menores fallaron pero continuamos"
    else
        log "[!] pkglist.txt no encontrado, instalando componentes críticos de respaldo..."
        apt-get install -y --no-remove bspwm sxhkd polybar rofi alacritty picom thunar zsh feh
    fi

    # Detectar el usuario real para no tirar rutas chuecas a /root
    local REAL_USER
    REAL_USER=${SUDO_USER:-$USER}
    local REAL_HOME
    REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

    log "[+] Desplegando configuraciones en el espacio de: $REAL_USER"

    # Configurar directorios base del home
    mkdir -p "$REAL_HOME/.config" "$REAL_HOME/Img" "$REAL_HOME/.fonts" "$REAL_HOME/.icons" "$REAL_HOME/.local/bin"

    # Copiar carpetas de configuración (.config) usando la ruta 'config/' del repo
    configs=("bspwm" "sxhkd" "polybar" "rofi" "alacritty" "picom" "gtk-3.0" "Thunar")
    for folder in "${configs[@]}"; do
        if [ -d "$SCRIPT_DIR/config/$folder" ]; then
            rm -rf "$REAL_HOME/.config/$folder"
            cp -r "$SCRIPT_DIR/config/$folder" "$REAL_HOME/.config/"
            log "  -> Carpeta .config/$folder copiado."
        fi
    done

    # Copiar archivos del home ocultos (zshrc, nanorc, profile)
    [ -f "$SCRIPT_DIR/home/.zshrc" ] && cp "$SCRIPT_DIR/home/.zshrc" "$REAL_HOME/"
    [ -f "$SCRIPT_DIR/home/.nanorc" ] && cp "$SCRIPT_DIR/home/.nanorc" "$REAL_HOME/"
    [ -f "$SCRIPT_DIR/home/.profile" ] && cp "$SCRIPT_DIR/home/.profile" "$REAL_HOME/"

    # Copiar tus scripts personalizados a .local/bin
    if [ -d "$SCRIPT_DIR/scripts" ]; then
        # Copiamos solo archivos sueltos para no arrastrar los modulares del instalador
        find "$SCRIPT_DIR/scripts" -maxdepth 1 -type f -exec cp {} "$REAL_HOME/.local/bin/" \;
    fi

    # Copiar Assets (Wallpapers, Fuentes, Iconos)
    [ -d "$SCRIPT_DIR/assets/wallpapers" ] && cp -r "$SCRIPT_DIR/assets/wallpapers"/* "$REAL_HOME/Img/" 2>/dev/null || true
    [ -d "$SCRIPT_DIR/assets/fonts" ] && cp -r "$SCRIPT_DIR/assets/fonts"/* "$REAL_HOME/.fonts/" 2>/dev/null || true
    [ -d "$SCRIPT_DIR/assets/icons/Papirus-Dark" ] && cp -r "$SCRIPT_DIR/assets/icons/Papirus-Dark" "$REAL_HOME/.icons/" 2>/dev/null || true

    # Refrescar caché de fuentes
    fc-cache -fv > /dev/null || true

    # Ajustes finos de permisos de ejecución
    log "[+] Ajustando permisos de ejecución internos..."
    chmod +x "$REAL_HOME/.config/bspwm/bspwmrc" 2>/dev/null || true
    chmod +x "$REAL_HOME/.config/sxhkd/sxhkdrc" 2>/dev/null || true
    [ -f "$REAL_HOME/.config/polybar/launch.sh" ] && chmod +x "$REAL_HOME/.config/polybar/launch.sh"
    chmod +x "$REAL_HOME/.local/bin"/* 2>/dev/null || true

    # Crear .xinitrc nativo seguro para arrancar con 'startx'
    echo "exec bspwm" > "$REAL_HOME/.xinitrc"

    # Corregir dueños de archivos al usuario real
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config" "$REAL_HOME/Img" "$REAL_HOME/.fonts" "$REAL_HOME/.icons" "$REAL_HOME/.local" "$REAL_HOME/.xinitrc" 2>/dev/null || true
    chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.zshrc" "$REAL_HOME/.nanorc" "$REAL_HOME/.profile" 2>/dev/null || true

    log "[z0m4-RICE] ¡Entorno gráfico y dotfiles desplegados con éxito!"
}

display_menu() {
    clear
    echo "╔════════════════════════════════════════════╗"
    echo "║       Parrot Conversion & Rice Setup       ║"
    echo "╠════════════════════════════════════════════╣"
    echo "║ 1) Install Core Edition + Custom Rice      ║"
    echo "║ 2) Install Home Edition (Parrot Desktop)   ║"
    echo "║ 3) Install Security Edition                ║"
    echo "║ 4) Install Hack The Box Edition            ║"
    echo "║ 5) >> SÓLO INSTALAR DOTFILES (BSPWM RICE)  ║"
    echo "║    (Usa esta opción si ya estás en Parrot) ║"
    echo "║ 6) Exit                                    ║"
    echo "╚════════════════════════════════════════════╝"
}

touch "$LOG_FILE"

while true; do
    display_menu
    read -r -p "Enter the option number: " option
    case $option in
        1) 
            check_system && blindar_sistema
            apt-get update && core && desplegar_entorno_nativo
            log "Instalación Core + Rice completada."
            ;;
        2) 
            check_system && blindar_sistema
            apt-get update && core && home
            log "Instalación Home completada."
            ;;
        3) 
            check_system && blindar_sistema
            apt-get update && core && security
            log "Instalación Security completada."
            ;;
        4) 
            check_system && blindar_sistema
            apt-get update && core && htb
            log "Instalación HTB completada."
            ;;
        5) 
            # Opción rápida solicitada: va directo a los bspwm y dotfiles sin tocar el SO base
            blindar_sistema
            apt-get update
            desplegar_entorno_nativo
            log "Despliegue exclusivo de Dotfiles completado."
            ;;
        6) 
            log "Exiting installation script..."
            exit 0 
            ;;
        *) 
            echo "Invalid option. Please try again." 
            ;;
    esac
    
    read -r -p "Press Enter to continue..."
done

#!/data/data/com.termux/files/usr/bin/bash
clear
#echo "[+] configurando mirrors..."

#cat > "$PREFIX/etc/apt/sources.list" <<EOF
#deb https://packages.termux.dev/apt/termux-main stable main
#EOF
set -e

# =========================
# UI ENGINE
# =========================
run_step() {
  local MSG="$1"
  local CMD="$2"
  local LOG="$HOME/.bootstrap.log"

  echo "[+] $MSG"

  bash -c "$CMD" >"$LOG" 2>&1 &
  local PID=$!

  local PROGRESS=0
  local WIDTH=20

  while kill -0 $PID 2>/dev/null; do
    PROGRESS=$((PROGRESS + 2))
    [ $PROGRESS -gt 90 ] && PROGRESS=90

    local FILLED=$((PROGRESS * WIDTH / 100))
    local EMPTY=$((WIDTH - FILLED))

    local BAR=$(printf "%${FILLED}s" | tr ' ' '=')

    if [ $PROGRESS -lt 100 ]; then
      BAR="${BAR}>"
      EMPTY=$((EMPTY - 1))
    fi

    BAR="${BAR}$(printf "%${EMPTY}s")"

    printf "\r[%-${WIDTH}s] %d%%" "$BAR" "$PROGRESS"

    sleep 0.2
  done

  wait $PID
  local STATUS=$?

  if [ $STATUS -eq 0 ]; then
    printf "\r[====================] 100%%\n"
    echo "[✓] $MSG"
  else
    echo ""
    echo "[✗] Error en: $MSG"
    echo "[!] Ver log: $LOG"
    exit 1
  fi
}

echo "[z0m4] bootstrap iniciado"

# =========================
# ETAPA 1 — BASE TERMUX
# =========================
run_step "update base" "pkg update"
run_step "upgrade base" "yes | pkg upgrade"

# =========================
# ETAPA 2 — REPOS
# =========================
run_step "instalando repos" "pkg install -y x11-repo tur-repo"

# =========================
# ETAPA 3 — SYNC
# =========================
run_step "sync repos" "pkg update && yes | pkg upgrade"

# =========================
# ETAPA 4 — BASE PKGS
# =========================
run_step "instalando base (x11, audio, tools)" \
"pkg install -y termux-x11-nightly pulseaudio git curl wget proot-distro"

# =========================
# ETAPA 5 — STORAGE
# =========================
echo "[+] configurando storage..."

if [ ! -d "$HOME/storage/shared" ]; then
  termux-setup-storage

  echo "[!] Esperando permisos..."

  TIMEOUT=15
  COUNT=0


  while [ ! -d "$HOME/storage/shared" ]; do
    sleep 1
    COUNT=$((COUNT + 1))

    if [ "$COUNT" -ge "$TIMEOUT" ]; then
      echo "[✗] Storage no concedido"
      exit 1
    fi
  done

  echo "[✓] Storage listo"
else
  echo "[✓] Storage ya configurado"
fi

# =========================
# ETAPA 6 — TECLADO
# =========================
echo ""
echo "[?] Configuración teclado"
echo "  [1] limpio"
echo "  [2] móvil (default)"
echo ""

read -p "Opción [1-2]: " opt
opt=${opt:-2}

PROP="$HOME/.termux/termux.properties"

case "$opt" in
  1)
    sed -i '/^extra-keys=/d' "$PROP"
    ;;
  2|*)
    sed -i '/^extra-keys=/d' "$PROP"
    echo "extra-keys=[['TAB','CTRL','ALT','LEFT','DOWN','UP','RIGHT']]" >> "$PROP"
    ;;
esac

# =========================
# ETAPA 7 — LIMPIEZA
# =========================
echo "[+] limpiando MOTD..."
: > "$PREFIX/etc/motd"

# =========================
# ETAPA 8 — DEBIAN
# =========================
run_step "instalando Debian" "proot-distro install debian"

# =========================
# ETAPA 9 — CONFIG DEBIAN
# =========================
run_step "configurando Debian base" "
proot-distro login debian -- bash -c '
apt update && apt upgrade -y &&
apt install -y adduser sudo nano git curl wget build-essential zsh &&
adduser z0m4 --gecos \"\" --disabled-password &&
echo \"z0m4:mariopro\" | chpasswd &&
usermod -aG sudo z0m4 &&
echo \"z0m4 ALL=(ALL:ALL) NOPASSWD: ALL\" > /etc/sudoers.d/z0m4 &&
chmod 0440 /etc/sudoers.d/z0m4
'
"

# =========================
# ETAPA 10 — DOTFILES
# =========================
run_step "instalando dotfiles" "
proot-distro login debian --user z0m4 -- bash -c '
cd ~ &&
[ ! -d dotfiles ] && git clone https://github.com/z0m4dst/dotfiles &&
cd dotfiles &&
bash install.sh
'
"

# =========================
# ETAPA 11 — CTL
# =========================
echo "[+] instalando ctl..."

CTL_SRC="$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/z0m4/dotfiles/ctl"
CTL_DST="$PREFIX/bin/ctl"

if [ -f "$CTL_SRC" ]; then
  cp "$CTL_SRC" "$CTL_DST"
  chmod +x "$CTL_DST"
  echo "[✓] ctl instalado"
else
  echo "[!] ctl no encontrado"
fi

# =========================
# ETAPA 12 — ZSH
# =========================
run_step "configurando zsh" "
proot-distro login debian -- bash -c '
usermod -s /usr/bin/zsh z0m4
'
"

# =========================
# FINAL
# =========================
echo ""
echo "[✔] Instalación completa"
echo ""
echo "Reinicia Termux"
echo ""
echo "  proot-distro login debian --user z0m4"
echo "  ctl start"
echo ""

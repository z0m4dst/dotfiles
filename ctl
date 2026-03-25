#!/data/data/com.termux/files/usr/bin/bash

set -e

LOG="$HOME/.ctl.log"
ACTION="$1"

log() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG"
}

is_running() {
    pgrep -f termux-x11 >/dev/null
}

# =========================
# START (TODO el entorno)
# =========================
start_x11() {
    if is_running; then
        log "X11 ya está corriendo"
        return
    fi

    log "Limpiando sesiones anteriores..."
    pkill -f termux.x11 2>/dev/null || true
    pkill -f pulseaudio 2>/dev/null || true

    # AUDIO
    log "Iniciando audio..."
    pulseaudio --start \
      --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" \
      --exit-idle-time=-1

    # X11
    log "Iniciando servidor X11..."
    export XDG_RUNTIME_DIR=${TMPDIR}
    export DISPLAY=:0

    termux-x11 :0 >/dev/null 2>&1 &
    sleep 3

    log "Abriendo app gráfica..."
    am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 \
    || monkey -p com.termux.x11 -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1

    sleep 2

    # DEBIAN + BSPWM
    log "Lanzando Debian + bspwm..."

    proot-distro login debian --shared-tmp -- /bin/bash -c '

      export DISPLAY=:0
      export PULSE_SERVER=127.0.0.1
      export XDG_RUNTIME_DIR=/tmp

      # DBUS limpio
      if [ ! -d /run/dbus ]; then
        mkdir -p /run/dbus
      fi

      rm -f /run/dbus/pid
      dbus-daemon --system --fork

      su - z0m4 -c "
        export DISPLAY=:0
        export PULSE_SERVER=127.0.0.1
        export XDG_RUNTIME_DIR=/tmp

        pkill -x sxhkd 2>/dev/null || true
        pkill -x picom 2>/dev/null || true
        pkill -x polybar 2>/dev/null || true

        dbus-launch --exit-with-session bspwm
      "
    ' &
}

# =========================
# STOP
# =========================
stop_x11() {
    log "Deteniendo entorno..."

    proot-distro login debian --shared-tmp -- /bin/bash -c '
        pkill -f bspwm
        pkill -f sxhkd
        pkill -f polybar
        pkill -f picom
    ' 2>/dev/null || true

    sleep 1

    pkill -f termux-x11 2>/dev/null || true
    kill -9 $(pidof termux-x11) 2>/dev/null || true

    sleep 1

    kill -9 $(pidof app_process) 2>/dev/null || true

    pkill -f pulseaudio 2>/dev/null || true

    log "Entorno detenido"
}

# =========================
# RESTART
# =========================
restart_x11() {
    log "Reiniciando entorno..."
    stop_x11
    sleep 2
    start_x11
}

# =========================
# STATUS
# =========================
status_x11() {
    echo "===== STATUS ====="
    echo "X11: $(pgrep -f termux-x11 >/dev/null && echo RUNNING || echo STOPPED)"
    echo "pulseaudio: $(pgrep -f pulseaudio >/dev/null && echo RUNNING || echo STOPPED)"
    echo "bspwm: $(pgrep bspwm >/dev/null && echo RUNNING || echo STOPPED)"
    echo "sxhkd: $(pgrep sxhkd >/dev/null && echo RUNNING || echo STOPPED)"
    echo "polybar: $(pgrep polybar >/dev/null && echo RUNNING || echo STOPPED)"
    echo "picom: $(pgrep picom >/dev/null && echo RUNNING || echo STOPPED)"
}

# =========================
# LOGS
# =========================
logs() {
    tail -n 50 "$LOG"
}

# =========================
# DISPATCH
# =========================
case "$ACTION" in
    start)
        start_x11
        ;;
    stop)
        stop_x11
        ;;
    restart)
        restart_x11
        ;;
    status)
        status_x11
        ;;
    logs)
        logs
        ;;
    *)
        echo "Uso: ctl {start|stop|restart|status|logs}"
        ;;
esac
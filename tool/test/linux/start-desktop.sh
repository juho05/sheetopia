#!/usr/bin/env bash
# Container entry point: VNC display :1 with an Xfce session, a session bus,
# an unlocked keyring and the desktop portal. Commands run later with
# `linux_env.sh sh` join this session via ~/.e2e-session.env.
set -euo pipefail

GEOMETRY="${GEOMETRY:-1280x960}"
Xvnc :1 -geometry "$GEOMETRY" -depth 24 -SecurityTypes None -localhost no \
  -rfbport 5901 -nolisten tcp -AlwaysShared -AcceptSetDesktopSize >/tmp/xvnc.log 2>&1 &
for _ in $(seq 1 50); do
  [ -S /tmp/.X11-unix/X1 ] && break
  sleep 0.2
done

# A system bus with BlueZ like a stock desktop without Bluetooth hardware.
sudo mkdir -p /run/dbus
sudo dbus-daemon --system --fork || echo "warning: no system bus" >&2
sudo /usr/local/bin/e2e-fake-bluez >/tmp/fake-bluez.log 2>&1 &

# Set before the bus starts so D-Bus activated services (the portal) see it.
export XDG_CURRENT_DESKTOP=XFCE XDG_SESSION_TYPE=x11 XDG_SESSION_DESKTOP=xfce
exec dbus-run-session -- bash -c '
  set -e
  {
    echo "export DISPLAY=$DISPLAY"
    echo "export DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS"
    echo "export XDG_CURRENT_DESKTOP=$XDG_CURRENT_DESKTOP XDG_SESSION_TYPE=$XDG_SESSION_TYPE XDG_SESSION_DESKTOP=$XDG_SESSION_DESKTOP"
  } > ~/.e2e-session.env
  # Unlocked login keyring for the Secret Service (sync credentials).
  # One daemon that creates/unlocks the login keyring with the user password.
  eval "$(printf "sheetopia" | gnome-keyring-daemon --replace --daemonize --unlock --components=secrets)"
  echo "export GNOME_KEYRING_CONTROL=${GNOME_KEYRING_CONTROL:-}" >> ~/.e2e-session.env
  # No screen saver or blanking during tests.
  xset s off -dpms s noblank || true
  touch ~/.e2e-desktop-ready
  exec startxfce4
'

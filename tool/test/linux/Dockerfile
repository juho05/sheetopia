# Throwaway Linux desktop for the Sheetopia E2E tests: Ubuntu 24.04 with Xfce
# on a VNC display, a session bus, the desktop portal and a keyring, like a
# fresh user desktop. Built and run by tool/test/scripts/linux_env.sh.
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      xfce4 xfce4-terminal xfce4-settings thunar mousepad \
      tigervnc-standalone-server tigervnc-tools \
      dbus dbus-x11 bluez python3-dbus python3-gi \
      xdotool wmctrl x11-xserver-utils x11-utils sqlite3 \
      xdg-desktop-portal xdg-desktop-portal-gtk xdg-utils desktop-file-utils \
      libglib2.0-bin dconf-service dconf-gsettings-backend \
      gnome-keyring libsecret-tools \
      libgtk-3-0t64 libglu1-mesa libgl1-mesa-dri libegl1 mesa-utils \
      libfuse2t64 fuse3 \
      alsa-utils \
      adwaita-icon-theme gnome-themes-extra fonts-dejavu-core \
      locales tzdata sudo socat curl ca-certificates zip unzip file procps at-spi2-core \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen en_US.UTF-8 de_DE.UTF-8

# Ubuntu ships no portals.conf for Xfce, without it the portal has no Settings
# backend (color scheme).
RUN mkdir -p /etc/xdg/xdg-desktop-portal \
    && printf '[preferred]\ndefault=gtk\n' >/etc/xdg/xdg-desktop-portal/portals.conf

# The image's default "ubuntu" user has uid 1000, replace it by the test user.
RUN userdel -r ubuntu 2>/dev/null; \
    useradd -m -u 1000 -s /bin/bash -G sudo,audio,video sheetopia \
    && echo 'sheetopia ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/sheetopia \
    && echo 'sheetopia:sheetopia' | chpasswd

# A stand-in browser: links the app opens are logged instead of loading a
# web page, so tests can check exactly which URL was opened.
COPY open-url.sh /usr/local/bin/e2e-open-url
COPY e2e-browser.desktop /usr/share/applications/e2e-browser.desktop
COPY e2e-browser-helper.desktop /usr/share/xfce4/helpers/e2e-browser.desktop
COPY start-desktop.sh /usr/local/bin/start-desktop
COPY midi-send.sh /usr/local/bin/e2e-midi-send
COPY fake-bluez.py /usr/local/bin/e2e-fake-bluez
COPY desktop-setup.sh /usr/local/bin/e2e-desktop-setup
COPY e2e-desktop-setup.desktop /etc/xdg/autostart/e2e-desktop-setup.desktop
RUN chmod +x /usr/local/bin/e2e-open-url /usr/local/bin/start-desktop /usr/local/bin/e2e-midi-send \
      /usr/local/bin/e2e-fake-bluez /usr/local/bin/e2e-desktop-setup

USER sheetopia
WORKDIR /home/sheetopia
ENV LANG=en_US.UTF-8 DISPLAY=:1 BROWSER=/usr/local/bin/e2e-open-url
RUN mkdir -p ~/Downloads ~/e2e ~/.config/autostart ~/.config/xfce4 \
    && printf 'WebBrowser=e2e-browser\n' >~/.config/xfce4/helpers.rc \
    && xdg-mime default e2e-browser.desktop x-scheme-handler/http x-scheme-handler/https text/html \
    && xdg-settings set default-web-browser e2e-browser.desktop 2>/dev/null || true

EXPOSE 5901 18181
CMD ["/usr/local/bin/start-desktop"]

#!/usr/bin/env bash
# Runs once at session start (autostart): removes the bottom dock, whose
# launchers sit where clicks near the bottom edge land, and keeps the top
# panel with the window list.
for _ in $(seq 1 30); do
  panels="$(xfconf-query -c xfce4-panel -p /panels 2>/dev/null | grep -E '^[0-9]+$' || true)"
  [ -n "$panels" ] && break
  sleep 1
done
first="$(head -1 <<<"$panels")"
[ -n "$first" ] || exit 0
if [ "$(wc -l <<<"$panels")" -gt 1 ]; then
  xfconf-query -c xfce4-panel -p /panels -t int -s "$first" -a
  xfce4-panel -r
fi

#!/usr/bin/env bash
# Usage: e2e-midi-send [-p client:port] [-r] <hex bytes>
#   e2e-midi-send 90 3C 7F 80 3C 00     note on/off
#   e2e-midi-send B0 40 7F              CC 64 on
#
# Sends MIDI messages into a VirMIDI port through the ALSA sequencer, which
# is how they reach an app reading the VirMIDI raw device (writing to the raw
# device with amidi only reaches the sequencer side). The port defaults to
# the first VirMIDI port.
#
# The kernel's VirMIDI encoder drops repeated status bytes (running status,
# B0 40 7F then B0 40 00 arrives as B0 40 7F 40 00), also across calls. A
# short SysEx (F0 7D F7) before every message resets it, so each message
# arrives with its status byte. -r leaves running status on.
set -euo pipefail

port=""
running=0
while [ $# -gt 0 ]; do
  case "$1" in
    -p) port="$2"; shift 2 ;;
    -r) running=1; shift ;;
    *) break ;;
  esac
done
[ $# -gt 0 ] || { echo "usage: e2e-midi-send [-p client:port] [-r] <hex bytes>" >&2; exit 2; }
if [ -z "$port" ]; then
  port="$(aplaymidi -l | awk '/VirMIDI/ {print $1; exit}')"
  [ -n "$port" ] || { echo "no VirMIDI port (is snd-virmidi loaded on the host?)" >&2; exit 1; }
fi

# A one-track Standard MIDI File, every message at delta time 0.
bytes=("$@")
track=""
i=0
while [ $i -lt ${#bytes[@]} ]; do
  status=$((16#${bytes[$i]}))
  case $((status >> 4)) in
    12 | 13) len=2 ;;
    8 | 9 | 10 | 11 | 14) len=3 ;;
    *) echo "unsupported status byte ${bytes[$i]}" >&2; exit 2 ;;
  esac
  [ $running = 1 ] || track+='\x00\xf0\x02\x7d\xf7'
  track+='\x00'
  for ((j = 0; j < len; j++)); do track+="\\x${bytes[$((i + j))]}"; done
  i=$((i + len))
done
track+='\x00\xff\x2f\x00'
length=$(printf "$track" | wc -c)
file="$(mktemp --suffix .mid)"
{
  printf 'MThd\x00\x00\x00\x06\x00\x00\x00\x01\x00\x60MTrk'
  printf "\\x$(printf %02x $((length >> 24 & 255)))\\x$(printf %02x $((length >> 16 & 255)))\\x$(printf %02x $((length >> 8 & 255)))\\x$(printf %02x $((length & 255)))"
  printf "$track"
} >"$file"
# -d 0: no 2 s pause after the end of the file
aplaymidi -d 0 -p "$port" "$file"
rm -f "$file"
echo "sent ${*} to $port"

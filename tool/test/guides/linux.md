# Linux guide

Your environment is a throwaway Ubuntu 24.04 desktop (Xfce) in a Docker
container on the Linux host, with its own home directory, session bus and
keyring. It runs the real x86_64 builds natively.

```sh
S=tool/test/scripts
$S/linux_env.sh app $RUN [--env K=V]... [--integration] [--targz]   # (re)start the release build
$S/linux_env.sh sh $RUN 'script'              # bash inside the desktop session (DISPLAY, D-Bus, keyring)
$S/linux_env.sh winstate $RUN                 # app window geometry and state (MAXIMIZED_*, FULLSCREEN, ...)
$S/linux_env.sh exec $RUN -- cmd ...          # plain command as the user
$S/linux_env.sh push $RUN <file> <dir>
$S/linux_env.sh pull $RUN <path> <dir>
```

The screen (1280x960) through the MCP tools: `screenshot`, `click` (with
`mod`, `button`, `double`), `move`, `drag`, `swipe`, `scroll`, `key`, `type`,
`zoom`, `batch`. Images are half size (640x480). `drag` rests before it
releases, so the app sees no fling: use `swipe` for swipe gestures.

User `sheetopia` (password `sheetopia`, passwordless sudo), home
`/home/sheetopia`. From the container the host is `host.docker.internal`
(the fake GitHub URL you get already uses it).

## Starting state

- Release AppImage of the version under test in `~/Downloads` (executable),
  not integrated; test files in `~/e2e/fixtures/`.
- App data: `~/.local/share/de.julianh.sheetopia`.
- `app` starts the integrated AppImage if there is one, else the newest one
  in `~/Downloads`, with output in `~/e2e/app.log`. It suppresses the
  "Integrate AppImage?" prompt unless you pass `--integration`. Fake GitHub:
  `--env SHEETOPIA_GITHUB_API_URL=<url> --env SHEETOPIA_GITHUB_WEB_URL=<url>`.

## Release builds

- Double-clicking the AppImage in Thunar is the user way; use it where a test
  is about starting the app.
- tar.gz: extract to `~/sheetopia-targz`, start it with `app --targz`.
- Integrated AppImage: `~/.local/bin/sheetopia`, desktop file
  `~/.local/share/applications/de.julianh.sheetopia.desktop`.
- Quit like a user: close the window (`key ["alt+f4"]` or its close button).
- Links: the desktop's "browser" records opened URLs in
  `~/e2e/opened-urls.log` instead of loading them.
- File dialogs (GTK, through the desktop portal): wait until the dialog
  shows (`wait_ms: 1500` on the click that opens it).
  - One file: `key ["ctrl+l"]`, `type` the full file path, `key ["return"]`.
  - Several files: `key ["ctrl+l"]`, `type` the folder path ending in `/`,
    `key ["delete", "return"]` (GTK appends a selected completion such as
    `bulk-` after the `/`, Delete removes it. Return on a folder opens it,
    it never chooses it), then Ctrl+click or Shift+click the files and click
    the dialog's confirm button.
  - Save dialogs: type the full target path into the name field, Return.
    The name field is prefilled: `ctrl+a` before typing. Pull with `ls` in
    the same Bash call, to see the name it really got.
  - The typing sequence is one `batch`, e.g. `[{"tool": "key", "keys":
    ["ctrl+l"]}, {"tool": "type", "text": "/home/sheetopia/e2e/fixtures/valid/"},
    {"tool": "key", "keys": ["delete", "return"]}]`.
  - A typed path bypasses the dialog's file type filter.
- Drag and drop: open Thunar on the folder and place it next to the app
  (`sh $RUN 'thunar ~/e2e/fixtures/valid & sleep 3; wmctrl -r valid -e 0,760,120,500,600'`),
  then `drag` files over (Ctrl+click to select several first). `look_mid:
  true` shows the screen while hovering over the target ("Drop to import").
- Window management: `wmctrl` and `xdotool` are installed. Check
  maximized/fullscreen with `winstate` (one call, also inside a polling loop).
- Theme: `xfconf-query -c xsettings -p /Net/ThemeName -s Adwaita-dark`
  (`Adwaita` for light) plus the portal's
  `gsettings set org.gnome.desktop.interface color-scheme prefer-dark`.
- Locale: start the app with `--env LC_TIME=de_DE.UTF-8` or `--env LC_TIME=en_US.UTF-8`.
- Wakelock: the app asks the desktop portal
  (`org.freedesktop.portal.Inhibit.Inhibit`), leaving closes the returned
  `org.freedesktop.portal.Request`. Watch it with
  `dbus-monitor --session "interface='org.freedesktop.portal.Inhibit'" "interface='org.freedesktop.portal.Request'"`
  in the background while opening and leaving the viewer. Like a stock
  Xubuntu, this desktop has no inhibitor backend behind the portal, so the
  screensaver state itself can't be observed: judge the calls and that the
  app shows no error.
- MIDI: only the host's VirMIDI devices are passed in, the app lists one
  `VirMIDI` device (`aplaymidi -l` also shows the host's other sequencer
  clients, ignore them). Send messages into the first VirMIDI device with
  `sh $RUN 'e2e-midi-send 90 3C 7F 80 3C 00'` (note on/off) or
  `e2e-midi-send B0 40 7F` / `B0 40 00` (CC 64 down/up, separate calls for a
  held pedal). Every message is preceded by a short SysEx (`F0 7D F7`), which
  makes the kernel send each message with its status byte; the app ignores
  it. `-r` sends with running status instead (`B0 40 7F` then `B0 40 00`
  arrives as `B0 40 7F 40 00`), only for a test about running status: the
  Linux MIDI plugin currently loses all input after it (see `issues.md`).
  `amidi -S` does not reach the app. If there is no VirMIDI port, the host
  lacks the module (`prereqs.sh` loads it): mark MIDI blocked.
- Bluetooth: the system bus has BlueZ without any adapter, like a desktop
  without Bluetooth hardware.
- Time: the container shares the host's clock and can't move it. Where a
  test needs time to pass, quit the app, shift the stored timestamps in its
  database (`sqlite3 ~/.local/share/de.julianh.sheetopia/sheetopia_database.sqlite`)
  and start it again. Say in the result that you did.

## Feature suite: the E2E driver build

The feature suite runs the profile build of the same commit with a driver
extension (`tool/test/app/main_e2e.dart`) in this desktop. It drives the
app's own logic with exact pointer kinds; platform behaviour is tested with
real input elsewhere (platform_features).

Start it with `$S/linux_env.sh driver $RUN [--env K=V]...` (stops the release
build, uses the same data). Then use the MCP `drive` tool, one action each,
`args` as below. Put actions you can do without looking in between into one
`batch` of `{"tool": "drive", "args": [...]}` items.

```
describe            visible texts, tooltips, fields, switches, icon buttons, one per line with [x,y,w,h]
tap --text 'Import files' | --tooltip 'Settings' | --at X,Y  [--kind mouse|touch|stylus] [--hold 800] [--index N] [--contains]
draw --kind stylus --points '100,200 150,220 200,260' [--duration 500] [--hold 1200]
gesture '{"pointers":[{"kind":"touch","points":[[100,300],[100,200]]},{"kind":"touch","points":[[200,300],[200,400]]}],"durationMs":400}'
scroll --at X,Y --dy 120 [--kind trackpad]
key a | escape | arrowRight | z --mod control | z --mod control,shift
key --mod control --hold down   # hold Ctrl for a following click, then --hold up
type 'text' [--replace] [--submit]
drop /home/sheetopia/e2e/fixtures/valid/x.pdf [--at X,Y]   # simulated drop (container paths)
window --size 390x844 | --fullscreen true | --maximize
wait --text 'Import successful!' [--gone] [--timeout 15000]
settle | route
back                # system back, like the Android back button
```

e.g. `drive {"args": ["tap", "--text", "Import files"]}`. Pass `look: false`
for describe, route, settle and wait: their text is the answer.

- Driver coordinates are logical pixels of the app (`describe` rects). The
  screenshot `drive` returns is the app content at half size: multiply its
  coordinates by 2.
- The driver sends pointer events with a device kind: the same stroke with
  `--kind stylus`, `touch`, `mouse`, `trackpad` must behave as the test says.
  `invertedStylus` is the eraser end. Multi-finger gestures are several
  pointers in one `gesture`.
- `draw` and `gesture` move every frame with real timestamps, so a swipe has
  the velocity of its distance over `--duration` (e.g. 600 px in 400 ms is a
  fling, the same with `--hold 300` at the end is not).
- Keys and text from the driver reach the app's focus system like hardware
  keys. Native dialogs (GTK file chooser, save dialog) are outside the app:
  while one is open use only the screen tools (`click`, `type`, `key`,
  `screenshot`). Several files: use the dialog as above or `drop` them.
- Icon-only buttons without tooltip appear as `button 0x<code point>`; tell
  them apart with the screenshot.
- `window --size WxH` resizes the app (the display is 1280x960) and reports
  the size it really got.

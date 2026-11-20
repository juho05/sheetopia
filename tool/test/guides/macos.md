# macOS guide

Your environment is a throwaway macOS VM (tart) on the Mac host. All commands
take the run directory `$RUN`; the VM state is in `$RUN/env/macos-test.env`.

```sh
S=tool/test/scripts
$S/macos_vm.sh sh $RUN 'any bash'          # run in the VM (user admin, GUI session)
$S/macos_vm.sh push $RUN <file> <vm dir>   # copy into the VM
$S/macos_vm.sh pull $RUN <vm path> <dir>   # copy out
```

## Seeing and operating the screen

The MCP tools work everywhere through VNC, including native dialogs, the
Finder, the menu bar and the Dock, with real mouse and keyboard events:
`screenshot`, `click` (with `mod`, `button`, `double`), `move`, `drag`,
`scroll`, `key` (e.g. `["cmd+q"]`, `["cmd+shift+g"]`, `["f"]`), `type`,
`zoom`, `batch`. Images are half size of the framebuffer.

F11 reaches macOS, not the app: it is the system's Show Desktop (a click on
the wallpaper brings the windows back). Toggle the app's fullscreen with F
or the fullscreen button, and say so where a test names F11.

Don't drive other apps with AppleScript (`osascript -e 'tell application
"Finder" ...'`): the guest asks for Automation permission and the command
hangs until someone answers. Use `open <folder>`, `pkill` and the screen
tools.

If a screen tool fails with "the VM restarted", the host's VM process
crashed (a known Virtualization.framework problem) and the VM booted again
from its disk: the app isn't running, open windows, the clock offset and
background processes are gone, the app's data on disk is kept. Relaunch and
redo what was lost; if your step can't continue, return
environmentOk=false, the orchestrator recreates the environment and runs the
step once more.

`cmd`, `option`, `ctrl` and `shift` are the Mac keys (mapped for the VM's VNC
server). Only US-keyboard characters can be typed directly; type accented
ones with dead keys (`key ["option+u"]` then `type u` gives ü).

VNC has a mouse and a keyboard, no trackpad gestures, touch or stylus: say so
where a test asks for those on macOS.

## Starting state

The version under test is installed in `/Applications`, the app is not
running, test files are in `/Users/admin/e2e/fixtures/`, the clock is real
time.

Where a test needs time to pass, move the VM's clock relative to now:
`$S/macos_vm.sh clock $RUN +15m|+2h|+1d|reset` (restoring the starting
state resets it).

`drag` with `look_mid: true` shows the screen while hovering over the target
before the drop.

## The app

```sh
$S/macos_vm.sh install-dmg $RUN $RUN/releases/v<version>/Sheetopia-<version>-macOS-universal.dmg
$S/macos_vm.sh launch $RUN [--fake-github <url>] [--env K=V]   # stdout/stderr → ~/e2e/app.log
$S/macos_vm.sh quit $RUN                             # or Cmd+Q via vnc (preferred)
```

- App data in the VM: `~/Library/Application Support/de.julianh.sheetopia`,
  update log: `~/Library/Logs/Sheetopia/update.log`.
- Version: `/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString'
  /Applications/Sheetopia.app/Contents/Info.plist`.
- The in-app updater replaces `/Applications/Sheetopia.app` and restarts it.
  The restarted app doesn't get `--fake-github` again; relaunch with it when a
  test needs the fake server afterwards.
- Test files: in native file dialogs press Cmd+Shift+G and type the folder
  path. In a save dialog the name field only takes a name (a typed path
  becomes part of the name): pick the folder with Cmd+Shift+G first, then
  click Save.
- Drag and drop: open the folder in Finder (`sh $RUN 'open ~/e2e/fixtures/valid'`),
  place Finder and the app side by side and `drag` from a file to the app.
  Several files: Cmd+click them in Finder first, then drag one of them.
- Wakelock: `pmset -g assertions` lists the app's assertion while a score is
  open.

## MIDI

`midi` runs a virtual device in the VM, a source and a destination named
like you say, that stays until stopped:

```sh
$S/macos_vm.sh midi $RUN start "E2E Pedal"    # listed on the app's MIDI page
$S/macos_vm.sh midi $RUN send on 60 100       # note on (channel 1)
$S/macos_vm.sh midi $RUN send off 60 0
$S/macos_vm.sh midi $RUN send cc 64 127       # control change
$S/macos_vm.sh midi $RUN stop                 # the device disappears
```

Start it, connect it in the app, press Set and send within a few seconds.
Stopping and starting it again is a device that goes away and comes back.
Don't use `sendmidi virt` for this: its device disappears as soon as it has
sent, and each sendmidi process is a different device to the app.

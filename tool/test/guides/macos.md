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
`scroll`, `key` (e.g. `["cmd+q"]`, `["cmd+shift+g"]`, `["f11"]`), `type`,
`zoom`, `batch`. Images are half size of the framebuffer.

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
  path.
- Drag and drop: open the folder in Finder (`sh $RUN 'open ~/e2e/fixtures/valid'`),
  place Finder and the app side by side and `drag` from a file to the app.
  Several files: Cmd+click them in Finder first, then drag one of them.
- Wakelock: `pmset -g assertions` lists the app's assertion while a score is
  open.

## MIDI

`sendmidi` is installed in the VM (`~/bin/sendmidi`). `virt <name>` creates a
virtual MIDI source the app sees as a device, for as long as sendmidi runs:

```sh
$S/macos_vm.sh sh $RUN '~/bin/sendmidi virt "E2E Pedal" on 60 100 off 60 0'   # note
$S/macos_vm.sh sh $RUN '~/bin/sendmidi virt "E2E Pedal" cc 64 127 cc 64 0'   # CC
```

To keep the device present while mapping it, loop in the background
(`nohup bash -c 'while true; do ~/bin/sendmidi virt "E2E Pedal" on 60 100 off 60 0; sleep 2; done' &`)
and kill the loop afterwards. `~/bin/sendmidi list` shows the ports.

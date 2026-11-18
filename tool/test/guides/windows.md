# Windows guide

Your environment is a throwaway Windows 11 VM (dockur/windows, QEMU/KVM in
a Docker container) on the Linux host. All commands take the run directory
`$RUN`; the VM state is in `$RUN/env/windows-test.env`.

```sh
S=tool/test/scripts
$S/windows_vm.sh sh $RUN 'PowerShell'         # over SSH: elevated, sees no windows
$S/windows_vm.sh desktop $RUN 'PowerShell'    # in the desktop session: unelevated, sees and opens windows
$S/windows_vm.sh exec $RUN -- 'cmd line'      # cmd.exe over SSH
$S/windows_vm.sh winstate $RUN                # app window geometry and MAXIMIZED/MINIMIZED/FULLSCREEN/FOREGROUND
$S/windows_vm.sh push $RUN <file> <vm dir>    # copy into the VM
$S/windows_vm.sh pull $RUN <vm path> <dir>    # copy out
```

User `sheetopia` (password `sheetopia`, administrator), home
`C:\Users\sheetopia`. VM paths may use `/` or `\`. Start programs a user
would see (Explorer, Edge) with `desktop`, e.g. `desktop $RUN 'explorer.exe
C:\Users\sheetopia\e2e\fixtures\valid'`: whatever `sh` starts runs invisibly
in the SSH session.

## Seeing and operating the screen

The screen (1280x800) through the MCP tools: `screenshot`, `click` (with
`mod`, `button`, `double`), `move`, `drag`, `swipe`, `scroll`, `key`, `type`,
`zoom`, `batch`. Images are half size (640x400). Modifiers are `ctrl`,
`alt`, `shift` and `super` (the Windows key), e.g. `key ["alt+f4"]`,
`["super+left"]`. Only US-keyboard characters can be typed.

VNC has a mouse and a keyboard, no touch, pen or trackpad: say so where a
test asks for those on Windows.

## Starting state

- The version under test is installed for all users in
  `C:\Program Files\Sheetopia` (Start menu entry Sheetopia), the app is not
  running, test files are in `C:\Users\sheetopia\e2e\fixtures\`, the
  installer in `~\Downloads`, the clock is real time.
- App data: `C:\Users\sheetopia\AppData\Roaming\juho05\Sheetopia`
  (database `sheetopia_database.sqlite`).
- Where a test needs time to pass, move the clock relative to now:
  `$S/windows_vm.sh clock $RUN +15m|+2h|+1d|reset` (restoring the starting
  state resets it).

## The app

```sh
$S/windows_vm.sh launch $RUN [--fake-github <url>] [--env K=V]... [--zip]   # stdout/stderr -> ~\e2e\app.log
$S/windows_vm.sh quit $RUN                     # kills it, Alt+F4 quits like a user
$S/windows_vm.sh install-exe $RUN $RUN/releases/v<version>/Sheetopia-<version>-windows-x86-64.exe   # silent install
```

- Double-clicking the Start menu entry or the exe in Explorer is the user
  way; use it where a test is about starting the app. `launch` is the way
  to pass environment variables. An app started with `launch` isn't
  focused: click into it before pressing keys.
- Zip release: extract it to `C:\Users\sheetopia\sheetopia-zip`, start it
  with `launch --zip`.
- Version: Settings > About, or `sh $RUN '(Get-Item "C:\Program
  Files\Sheetopia\sheetopia.exe").VersionInfo.ProductVersion'`.
- The in-app updater downloads the installer, exits the app and starts the
  installer's wizard: click through it (UAC prompts show on the VNC screen,
  answer Yes), its last page starts the new version. The restarted app
  doesn't get `--fake-github` again; relaunch with it when a test needs the
  fake server afterwards.
- File dialogs: type the full path into the file name field (`ctrl+l` or
  `alt+n` focuses it) and press Return; a folder path opens the folder.
  Several files: open the folder that way, then Ctrl+click the files and
  press Open. Save dialogs: the name field is prefilled, `ctrl+a` before
  typing the full target path. A typed full path bypasses the dialog's file
  type filter.
- Drag and drop: open the folder with `desktop $RUN 'explorer.exe <dir>'`,
  snap Explorer and the app side by side (`key ["super+left"]` on one,
  pick the other in Snap Assist) and `drag` files over (Ctrl+click several
  first). `look_mid: true` shows the screen while hovering over the target.
- Fullscreen and window state: `winstate` in one call (also in a polling
  loop). FULLSCREEN means covering the whole screen without a frame.
- Links open in Edge (no first-run screens); check its address bar.
- Wakelock: `sh $RUN 'powercfg /requests'` lists `sheetopia.exe` under
  DISPLAY while a score is open.
- Bluetooth: the VM has no Bluetooth adapter.
- Score processing: `sqlite3` is not installed, pull the database
  (`pull $RUN C:/Users/sheetopia/AppData/Roaming/juho05/Sheetopia/sheetopia_database.sqlite
  $RUN/scratch/`, app quit first) and query it on the host.

## MIDI

loopMIDI's driver is installed. `midi start [name]` creates a virtual MIDI
device (default "E2E Pedal") the app sees, present until `midi stop`;
`midi send` sends hex bytes through it. `midi start` restarts the Windows
MIDI service, which drops the app's open MIDI connections, so start the
device before connecting it in the app:

```sh
$S/windows_vm.sh midi $RUN start "E2E Pedal"
$S/windows_vm.sh midi $RUN send 90 3C 7F 80 3C 00   # note on/off
$S/windows_vm.sh midi $RUN send B0 40 7F            # CC 64 down, B0 40 00 up
$S/windows_vm.sh midi $RUN stop
```

If `midi start` fails with "loopMIDI is not installed", mark the MIDI
device tests blocked.

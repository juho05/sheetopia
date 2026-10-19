# Android guide

Your environment is a throwaway Android emulator (Pixel 7, Google APIs x86_64
image with KVM, rooted adb) on the Linux host, 1080x2400.

The screen through the MCP tools: `screenshot`, `tap` (`stylus` for the
pen), `long_press`, `swipe`, `drag`, `key`, `type`, `ui`, `zoom`, `batch`.
Images are a third of the size (360x800), `zoom` reads small text. `ui` lists the visible elements (Flutter exposes its
semantics) with bounds in image pixels: use it to find texts and buttons
while navigating (see common.md for when to look).

```sh
S=tool/test/scripts
$S/android.sh adb $RUN shell ...         # anything else
$S/android.sh push-files $RUN <file>...  # see Sharing
$S/android.sh clock $RUN +15m|+2h|+1d|reset   # move the emulator's clock, relative to now
```

## Starting state

- The release APK of the version under test is installed, the app is
  stopped, `demo-library.zip` is in `Download/`. Test files stay on the host
  in `$RUN/fixtures/`, push the ones you need with `push-files`.
- Start: `$S/android.sh adb $RUN shell monkey -p de.julianh.sheetopia 1`, or
  tap the icon in the launcher (user way).
- The clock is real time (restoring the starting state resets it).
- Chrome opens links directly, without first-run screens.

## The app

- Install the release APK like an update or a fresh install:
  `$S/android.sh adb $RUN install -r <apk>` (`-r` keeps data). The release APKs
  are in `$RUN/releases/v<version>/` (`android-x64` for this emulator).
- Fake GitHub: `$S/android.sh fake-github $RUN <url>` sets the system
  properties the app reads at start (`off` to clear), then force stop and
  restart the app (`adb shell am force-stop de.julianh.sheetopia`).
- Installing updates needs "Install unknown apps" for Sheetopia: the app
  explains and opens the settings page; allow it there like a user.
- Data: `adb shell run-as` doesn't work on release builds, use root:
  `$S/android.sh adb $RUN shell ls /data/data/de.julianh.sheetopia/`.

## Sharing

Put files on the device: `$S/android.sh push-files $RUN <file>...` copies them
to `Download/` and prints their `content://` URIs.

- **Receive, the user way:** open the Files app ("Files" in the launcher,
  `com.google.android.documentsui`), go to Downloads, long-press to select one
  or several files, Share, pick Sheetopia. Do this for single, multiple,
  invalid and mixed selections.
- **Send:** sharing from the app opens the system share sheet; share the PDF
  back into Sheetopia and check the result.
- Cold start sharing: force stop the app first, then share into it.

## Other platform behaviour

- Drag and drop: split screen (app switcher > app icon > Split screen) with
  the Files app, then the `drag` tool from a file onto Sheetopia (the first
  drag may only select the file, drag again). `look_mid: true` shows the
  screen while hovering over the target.
- Scanning: the scanner needs a Play services module the emulator can't
  download, so only the failure path ("Failed to scan score!") is testable.
- Wakelock: `adb shell dumpsys power | grep -i -A2 wake_lock`.

## MIDI

The emulator has no MIDI devices and no Bluetooth; only check that the MIDI
page handles that gracefully.

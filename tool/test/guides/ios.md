# iOS guide

Your environment is throwaway, headless iOS simulators on the Mac host: a
phone (default) and, for iPad-only behaviour like Split View drag and drop, a
tablet. Every command takes `--sim tablet` right after `$RUN` to address the
tablet (`up` it first). The app is a
simulator build of the same commit (the release .ipa can't run in a
simulator, and there is no in-app updater on iOS).

The screen through the MCP tools, each with `sim: "phone"|"tablet"`:
`screenshot`, `tap`, `long_press`, `swipe`, `type`, `button`, `describe`,
`zoom`, `batch`. Images are in points (the unit axe uses), so image coordinates,
`describe` frames and the gesture tools' coordinates are all the same: tap
what you see where you see it. `describe` lists the labelled and interactive
elements of the accessibility tree, one line each with its frame; Flutter
content is labelled by its text, use it to find buttons while navigating (see
common.md for when to look). System sheets (share sheet, Files) are not in it,
look at the screenshot there.

```sh
S=tool/test/scripts
$S/ios_sim.sh up $RUN --sim tablet            # the tablet, when a test needs it
$S/ios_sim.sh install $RUN --sim tablet $RUN/builds/current/ios/Runner.app
$S/ios_sim.sh launch $RUN | terminate $RUN
$S/ios_sim.sh axe $RUN tap --label 'Share'    # by label, reliable for system UI
$S/ios_sim.sh files $RUN <file>...            # put files into Files > On My iPhone
$S/ios_sim.sh simctl $RUN launch com.apple.DocumentsApp       # Files app
```

`axe help <subcommand>` explains every option.

## Starting state

The phone simulator has the build under test installed, the app is not
running. Test files stay on the host in `$RUN/fixtures/`, put the ones you
need into Files with `files`. The tablet is not up until you start it.

## The tablet

Tests that name the iPad (drag and drop with Split View or Slide Over, the
share sheet's anchor) need the tablet; don't skip them because it is down:

```sh
$S/ios_sim.sh up $RUN --sim tablet
$S/ios_sim.sh install $RUN --sim tablet $RUN/builds/current/ios/Runner.app
$S/ios_sim.sh launch $RUN --sim tablet
```

then pass `sim: "tablet"` to the screen tools. Bringing it up takes about a
minute. Leave it up when you're done, the orchestrator removes it.

## Sharing

- **Receive:** copy files with `files`, open the Files app, Browse > On My
  iPhone, Select, pick one or several, Share, choose Sheetopia (share
  extension). The app opens with "Import as". Repeat for single, multiple,
  invalid and mixed selections, with the app running and terminated.
- **Send:** sharing from the app opens the iOS share sheet. Its header shows
  the title the app sets ("Share score file", "Share logs", "Export scores")
  with the file type and size, not the file name; the file name shows in
  the Save to Files sheet ("Save as") and on disk. Use "Save to Files",
  then Save at the top right: the sheet closes and the app shows its
  success toast. `$S/ios_sim.sh files-dir $RUN` prints the host folder of
  "On My iPhone" to check the saved file (or browse it in the Files app).
  Or share into Sheetopia.

## Time

The simulator uses the host's clock, which must not be changed. Where a test
needs time to pass, terminate the app, shift the stored timestamps in its
database (`xcrun simctl get_app_container <udid> de.julianh.sheetopia data`
is its data directory on the host) and launch it again. Say in the result
that you did.

## MIDI

The simulator has its own MIDI server: devices on the host (sendmidi, the
Mac's own) never show up in it. `midi` runs a virtual device inside the
simulator instead, a source and a destination named like you say, that
stays until stopped:

```sh
$S/ios_sim.sh midi $RUN start "E2E Pedal"     # listed on the app's MIDI page
$S/ios_sim.sh midi $RUN send on 60 100        # note on (channel 1)
$S/ios_sim.sh midi $RUN send off 60 0
$S/ios_sim.sh midi $RUN send cc 64 127        # control change
$S/ios_sim.sh midi $RUN stop                  # the device disappears
```

Start it, connect it in the app, press Set and send within a few seconds.
`$RUN/logs/ios-phone-midi.log` shows what was sent. Stopping and starting
it again is a device that goes away and comes back.

The simulator has no Bluetooth: the MIDI page shows "Bluetooth not
available" and lists only this device, there is no Bluetooth prompt.

## Wakelock

The app disables the idle timer while a score (or setlist, routine or
exercise play) is open. The simulator never auto-locks, but SpringBoard logs
the app's request:

```sh
$S/ios_sim.sh simctl $RUN spawn log show --last 1m --style compact \
  --predicate 'category == "IdleTimer" AND eventMessage CONTAINS "requested idle timer behavior disabled"'
```

must show `YES` after opening the viewer and `NO` after leaving it.

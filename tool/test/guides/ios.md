# iOS guide

Your environment is throwaway, headless iOS simulators on the Mac host: a
phone (default) and, for iPad-only behaviour like Split View drag and drop, a
tablet. Every command takes `--sim tablet` right after `$RUN` to address the
tablet (`up` it first). The app is a
simulator build of the same commit (the release .ipa can't run in a
simulator, and there is no in-app updater on iOS).

The screen through the MCP tools, each with `sim: "phone"|"tablet"`:
`screenshot`, `tap`, `long_press`, `swipe`, `type`, `button`, `describe`,
`zoom`, `batch`. Images are in points (the unit axe uses), so image coordinates and
`describe` frames match. `describe` is the accessibility tree: Flutter content
is labelled by its text, use it to find buttons while navigating (see
common.md for when to look).

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

## Sharing

- **Receive:** copy files with `files`, open the Files app, Browse > On My
  iPhone, Select, pick one or several, Share, choose Sheetopia (share
  extension). The app opens with "Import as". Repeat for single, multiple,
  invalid and mixed selections, with the app running and terminated.
- **Send:** sharing from the app opens the iOS share sheet; use "Save to
  Files" and check the file appears in Files, or share into Sheetopia.

## Time

The simulator uses the host's clock, which must not be changed. Where a test
needs time to pass, terminate the app, shift the stored timestamps in its
database (`xcrun simctl get_app_container <udid> de.julianh.sheetopia data`
is its data directory on the host) and launch it again. Say in the result
that you did.

## MIDI

The simulator uses the host's CoreMIDI. A virtual source created on the host
appears in the simulator:
`~/.cache/sheetopia-e2e/bin/sendmidi virt "E2E Pedal" on 60 100 off 60 0`
(keep it running in the background while mapping, see the macOS guide). This
touches only the host's MIDI device list while it runs, nothing else.

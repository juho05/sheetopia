# Update test guide

The in-app updater is tested twice per update platform (macOS, Linux
AppImage, Android):

- **old → new**: the previous published release (`versions.previous` in
  `$RUN/run.json`, assets in `$RUN/releases/<tag>/`) updates to the build under
  test (`versions.current`, assets in `$RUN/releases/v<current>/`).
- **new → next**: the build under test updates to the imaginary next release
  (`versions.next`): the same commit with a bumped version.

Both run against a fake GitHub that only you control:

```sh
S=tool/test/scripts
URL=$($S/fake_github.sh start $RUN <platform> <tag>...)   # e.g. v0.7.0 v0.7.1
$S/fake_github.sh serve $RUN <platform> <tag>...           # change what is served
$S/fake_github.sh requests $RUN <platform>                 # what the app fetched
$S/fake_github.sh stop $RUN <platform>
```

Hand `$URL` to the app: macOS `macos_vm.sh launch $RUN --fake-github $URL`,
Linux `linux_env.sh app $RUN --env SHEETOPIA_GITHUB_API_URL=$URL --env SHEETOPIA_GITHUB_WEB_URL=$URL`, Android `android.sh fake-github $RUN $URL` and restart the app.
Releases older than the one supporting these variables ignore them and talk to
the real GitHub; that's why `old_to_new_update` may be disabled in the plan.

## Preparing the starting state

1. The orchestrator already installed the starting version and copied the
   test files (see "Starting state" in your platform guide).
2. Start it once without the fake server, get through first-start prompts
   (Android: Bluetooth permission; Linux: answer "Integrate AppImage?" with
   **Later** unless your test is about integration).
3. If the library is empty, import the run's demo library through Settings >
   Import/Export > Import, picking `demo-library.zip` in the native file
   dialog.
4. Change a few settings so you can check they survive: theme Dark, "Flash on
   page turn" on, log level Debug.
5. **Baseline export:** Settings > Import/Export > Export, save it and copy
   it to `$RUN/results/<platform>-<phase>-before.zip`, where `<phase>` is
   `old-to-new` or `new-to-next` (the update it is the baseline for; setup
   uses `setup` when old → new is off). The export after the update is
   `<platform>-<phase>-after.zip`.
   - macOS/Linux: save dialog, then `pull` the file.
   - Android: the share sheet, save to Downloads/Files, then
     `android.sh adb $RUN pull /sdcard/Download/<file> <dest>`.
   Don't open scores between this export and the update.

## Running the update

1. Start the fake server with the starting and the target release, e.g.
   `start $RUN macos v0.7.0 v0.8.0`, and (re)start the app pointing at it.
2. The "New version available" dialog appears at start (if it was shown in the
   last day or you chose "Remind later", use Settings > Version Checking >
   Check now instead). Check its texts and buttons, then press Install.
   View opens the releases page and closes the dialog, Check now brings it
   back.
3. Watch the progress until the app restarts. Linux: Restart quits at once and
   the new version comes up about 10 s later (2 s delay plus the AppImage
   start). Click it once and poll the process list in one Bash loop before
   clicking again. On Android allow installing unknown apps and confirm the
   system installer; the installer ends the app, reopen it yourself.
4. `requests` must show the tag list and the download of exactly the asset for
   this platform and target version.

## Verifying

- Version: Settings > About (and on macOS Info.plist, on Android
  `adb shell dumpsys package de.julianh.sheetopia | grep versionName`).
- The toast "Successfully updated to v<target>!" appeared once; the dialog is
  gone after the restart. The toast only stays 2.5 s, too short for a
  screenshot after the relaunch: check the app log for the debug entry
  `Toast: Successfully updated to v<target>!` (exactly one, log level Debug
  from setup; Linux `sqlite3 ~/.local/share/de.julianh.sheetopia/sheetopia_database.sqlite
  "select time, message from log_message where message like 'Toast:%'"`,
  elsewhere Settings > Debug > View logs).
- The settings you changed are unchanged.
- Data: export again and diff against the baseline:
  `tool/test/scripts/tool.sh export_diff <before.zip> <after.zip> --json $RUN/results/<platform>-<phase>-diff.json`
  plus one `--ignore <pattern>` per entry of `data_verification.ignore_fields`
  in the plan. `MATCH` passes; any difference is a finding unless it is
  clearly a legitimate migration (explain it).
- For old → new also diff the baseline against `$RUN/demo-library.zip` and
  report the differences as information (they show what the old version
  changed on import).
- Look at the library, a setlist, an annotated score, practice statistics.
- `update.no_dialog_when_current`: serve only the target release and use
  Check now: no update offered.

If the update fails, collect the evidence (macOS `~/Library/Logs/Sheetopia/
update.log`, the app's logs page, `requests`), mark it failed and install the
target build directly so later phases can still run, saying so in your result.

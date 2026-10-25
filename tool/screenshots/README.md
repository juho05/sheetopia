# Screenshots

README and store screenshots of the demo library, captured from a fresh build.

```sh
tool/screenshots/screenshots.sh                     # asks which platforms
tool/screenshots/screenshots.sh --platforms linux --readme
tool/screenshots/screenshots.sh --platforms android --scenes library,filter
```

Output: `out/<run>/screenshots/<form factor>/<scene>.png`. `--readme` copies the Linux set to `screenshots/` as
`<scene>-<version>.png` and points `README.md` at it.

## Feature graphic

The 1024x500 Google Play feature graphic, `out/<run>/screenshots/feature-graphic.png`, from the macOS or Linux
`library` and `annotate` screenshots, rendered by headless Chrome or Chromium. Text at the top of
`cli/lib/feature_graphic.dart`. Render again without capturing:

```sh
tool/screenshots/screenshots.sh --feature-graphic tool/screenshots/out/<run>
```

## Platforms

Only those this host can build are offered.

| Form factor         | Size      | Capture                                                    |
|---------------------|-----------|------------------------------------------------------------|
| `linux`             | 2440x1496 | README, spectacle in a headless KWin at scale 2            |
| `macos`             | 2880x1800 | Mac App Store, `screencapture` of the window, title bar cropped |
| `android-phone`     | 1080x2160 | Google Play, throwaway emulator, demo mode status bar      |
| `android-tablet-7`  | 1200x1920 | same emulator, display size and density overridden, app reinstalled |
| `android-tablet-10` | 1600x2560 | same                                                       |
| `ios-iphone-6.3`    | 1206x2622 | App Store, throwaway simulator, status bar override        |
| `ios-iphone-duo`    | 1398x2034 | same, outer display, needs Xcode 27.1                      |
| `ios-ipad-13`       | 2064x2752 | same                                                       |

Play allows at most 2:1, so phones are 18:9 instead of their real 20:9. A new store slot is a `FormFactor` in `cli/lib/targets/`.

## What a run does

1. Builds the demo library (`tool/demo_library/build.py --now <run start>`).
2. Copies the working tree to `out/<run>/stage` and patches it there:
   - the sync icon always shows done,
   - login secrets stay in memory instead of the system keyring,
   - the macOS bundle id differs from the real app.
3. Builds `app/main_screenshots.dart` (the E2E driver build plus import, theme and navigation actions) with
   `VERSION_CHECK=false`.
4. Starts the app with fresh data, imports the library, plays each scene and captures it.

Requirements: Linux needs `kwin_wayland`, `kscreen-doctor`, `spectacle` and `dbus-daemon`, Android an SDK with
emulator, cmdline-tools and a non Play Store system image for the host CPU (adb root sets the time zone), iOS Xcode,
macOS the Screen Recording permission for the terminal (the window may be covered, not minimized; no cursor). All need `lilypond` for the demo library.

## Scenes

The README motifs in `cli/lib/scenes.dart`. `library` is light below the diagonal and dark above it, the rest are dark.
`--explore` starts the app with the library imported and waits, for writing scenes with
`tool/test/harness/bin/drive.dart`. It keeps the staged tree for `--stage`.

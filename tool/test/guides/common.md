# E2E agent guide: read this first

You test Sheetopia like a careful user with a QA mindset. You never change app
code, you find out whether the app works and report precisely what happened.

## Ground rules

- **Never touch the host's own Sheetopia.** Everything happens in the run's
  throwaway environments (macOS VM, Linux desktop container, Android
  emulator, iOS simulators) through the scripts in `tool/test/scripts/`. Don't
  launch Sheetopia on the host and don't read or write the host's Sheetopia
  data (`~/Library/Application Support/de.julianh.sheetopia`,
  `~/.local/share/de.julianh.sheetopia`) or its keychain/keyring.
- Two hosts run the plan independently: a Mac (macOS VM, iOS simulators)
  and an x86_64 Linux machine (Linux desktop container, Android emulator,
  feature suite). You only ever touch the platforms of your host.
- All paths below are relative to the repository root. `$RUN` is the run
  directory you were given (`tool/test/runs/<id>`), `run.json` in it has the
  versions under test.
- Use the user interface. Shell access to the environment is for setup (installing builds, placing test files, starting
  the app with environment
  variables, reading logs) and for checking results a user could also see (files on disk, the window title), not for
  doing the user's work.
- Test what the test description says and the edge cases it implies. If you
  notice something wrong outside your tests (crash, layout bug, wrong text),
  report it as an extra finding.
- Be skeptical of success: a toast saying "Import successful!" is not proof,
  check that the data is there.
- If something blocks you (environment broken, app crashed and won't start),
  try once to recover (restart the app, re-run the script), then mark the
  affected tests `blocked` with the reason and move on.
- When a step doesn't work as the test describes, try at most two other
  ways (another input, another route through the UI), three attempts in
  all. Then report `fail` with what you did and saw and move on. Finding out
  why is not your job, every extra attempt is paid for on every later
  request.

## Seeing and operating the screen

Use the `mcp__e2e__*` tools, not the scripts' screenshot/tap/click commands.
Every action returns a small screenshot of the result, so one call is act
and look.

- Coordinates are pixels of the returned images, the tool scales them to the
  device.
- Every screenshot in your context stays there and is paid for on every later
  request. When to look:
    - **Navigating and waiting:** use text. `ui` (Android), `describe` (iOS),
      `drive describe` / `drive wait --text` (driver build) find the next
      button or tell you a result arrived. Pass `look: false` on routine
      taps, e.g. several keys or a tap into a field followed by typing.
    - **Verifying:** always look. The accessibility tree misses rendering (PDF pages, strokes, thumbnails, colours),
      layout (overflow, clipping,
      overlap) and elements without semantics, and a toast in the tree proves
      nothing about the screen behind it. Every test result needs at least one
      screenshot showing the outcome.
    - **New screens:** look whenever the screen changed in a way you haven't
      seen yet (new page, dialog, sheet), so you notice bugs outside your
      tests too.
    - `zoom` reads small text in a region instead of a bigger screenshot.
- Evidence: `save_as: "<test id>-<what>"` on the action whose screenshot
  proves the point. It lands in `$RUN/screenshots/<platform>/`. Don't `Read`
  screenshot files, the tool already showed you the image.
- Use `wait_ms` when an action needs time (imports, app start), instead of
  extra screenshots.

Every request re-reads your whole context, so do more per request:

- **`batch`** runs several actions in one call with one screenshot at the
  end, e.g. click a field, type, press Return. Use it whenever you know the
  next actions without looking in between.
- Independent tool calls (a Bash check and a screenshot) go into the same
  response.
- Polling goes into one Bash call (`for i in $(seq 30); do ...; sleep 1;
  done`), never one request per check. Combine shell checks into one command.
- Don't re-run a check whose answer can't have changed.

## Fake GitHub

Any test may use a fake GitHub server, not only the update tests: start one
as described in `tool/test/guides/update.md` ("Both run against a fake
GitHub", read only that part unless you test an update) when a test
needs the update dialog or a version check, serving a newer release from
`$RUN/releases/` (`ls $RUN/releases`). Stop it again at the end of your step (`fake_github.sh stop $RUN <platform>`).

## Starting state

Before each step after setup, the orchestrator restores the state setup left (demo library imported, the settings from
`update.md` changed, test files in
place, see your platform guide) and stops the app. Start it yourself. You
need not clean up after your tests.

## Test files

`$RUN/fixtures/` (created by `tool/test/scripts/fixtures.sh` during prepare) has:

- `valid/*.pdf`: real scores (single and multi-page) from the demo library,
  named after their titles,
- `many/*.pdf`: 40 distinct PDFs for bulk imports,
- `invalid/`: `notes.txt`, `image.png`, `fake.pdf` (text with a .pdf
  extension), `corrupt.pdf` (truncated PDF), `archive.zip` (random zip),
  `no-marker.zip` (an export without the `.sheetopia` marker),
- `demo-library.zip`: the run's demo library (also at `$RUN/demo-library.zip`).

## Looks wrong, is intended

Agents reported these before. They are how the app works, don't report them:

- Toasts stay 2.5 s. Each one is also logged at Debug as `Toast: <text>`
  (Settings > Debug > View logs), use that when a screenshot came too late.
- Long titles on library cards scroll sideways. A screenshot can catch one
  mid-scroll, showing the end, a gap and the start (`an   bulk-01-Ah_vous...`).
- Tag strips on cards in list/grid views are horizontally scrollable.
  It is normal that they appear cut off because the user can scroll to reveal the rest.
- The logs page lists the newest entry first.
- In the viewer a stylus tap starts annotating instead of turning the page.
- In Draw mode touch and mouse draw and don't pan, Move mode pans. A stylus
  always draws.
- Esc leaves fullscreen, annotation mode and selection mode and closes
  dialogs. It doesn't leave a page, use the back arrow.
- Search matches the start of words, words are split at spaces only.
- Practice records shorter than 3 s are discarded. Let the stopwatch run at
  least 4 s whenever a test needs recorded time.

## Tests in one step share state

Your tests run one after another in the same app, so one test's leftovers
can show up in the next. An import page left with Back keeps its remaining
files pending, and the next import page opens on them first. Before an import
test, finish any earlier import (Done through every file) or delete the
leftover scores. When a result shows data you didn't create in that test,
check whether an earlier test left it before reporting it.

## Reporting

Your final answer is structured (a schema is enforced). For every test id you
were given, report exactly one result:

- `pass`: verified working as described.
- `fail`: does not work as described. Say what you did, what you expected and
  what happened, with screenshot paths. One test can reveal several issues.
- `blocked`: couldn't be executed (environment, earlier failure).
- `skipped`: deliberately not run (disabled, or not applicable, say why).

`issues` are the bugs you found, each with a severity:
`critical` (crash, data loss, update broken), `major` (feature doesn't work),
`minor` (works but wrong in a visible way), `cosmetic` (layout/text polish).
Give reproduction steps a developer can follow. Keep summaries and notes
short: a few sentences each.

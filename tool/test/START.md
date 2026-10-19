# Starting an E2E run

Instructions for the agent that starts a run. Work from the repository root.

## 1. Check the host

Run `tool/test/scripts/prereqs.sh --check`. If something is missing, report it
and stop. Don't install anything without asking.

## 2. Let the user choose

Ask all questions in one round with your question tool, as multi-select
questions. Preselect nothing, describe each option in one short line.

1. **Update tests**
   - old→current: previous release updated to the build under test
   - current→next: build under test updated to an imaginary next version
2. **Tests**
   - Platform features: OS and plugin behaviour with real input
   - Feature suite: the app's own logic (Linux host only)
3. **Platforms** (only this host's: Linux host Linux and Android, Mac macOS
   and iOS)

If old→current is selected, ask afterwards which release it starts from:
`latest` (recommended) or a tag like `v0.7.0`.

## 3. Build the arguments

- run id: `date +%Y-%m-%d_%H%M`.
- `--set`: one per option, `=true` if selected, `=false` if not:

| Option | Plan path |
|---|---|
| old→current | `phases.old_to_new_update.enabled` |
| current→next | `phases.new_to_next_update.enabled` |
| Platform features | `phases.platform_features.enabled` |
| Feature suite | `phases.feature_suite.enabled` |
| Linux / Android / macOS / iOS | `platforms.<linux\|android\|macos\|ios>.enabled` |
| Start release (old→current only) | `build.previous_release=<latest or tag>` |

Before starting:
- old→current: compare `version:` in `pubspec.yaml` with the start release.
  If they are equal, the update has nothing to do. Tell the user and ask
  whether to continue.
- Show the user the final command.

## 4. Start the run

Run the orchestrator as a background command (Bash `run_in_background`, no
timeout), e.g.

```sh
tool/test/scripts/tool.sh e2e 2026-10-15_1400 \
  --set phases.old_to_new_update.enabled=false --set phases.new_to_next_update.enabled=true \
  --set phases.platform_features.enabled=true --set phases.feature_suite.enabled=true \
  --set platforms.linux.enabled=true --set platforms.android.enabled=true
```

To continue an unfinished run (usage limit, crash, aborted), run
`tool/test/scripts/tool.sh e2e <its id> --resume` the same way: it keeps the
builds and finished steps and reruns the rest.

Rules:
- Only start the run. Don't run its steps yourself, and don't change app
  code or the plan.
- A run takes hours. Progress: `tool/test/runs/<id>/logs/orchestrator.log`,
  agent transcripts in `runs/<id>/agents/`. When it ends, give the user the
  `report` path and the counts from its last line (also in
  `runs/<id>/summary.json`). Agents hitting the usage limit wait for the
  reset, so a run can take longer than its log suggests.

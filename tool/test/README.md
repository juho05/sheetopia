# E2E tests

Agent-driven end-to-end tests of the real release builds. A Claude Code
workflow builds the app with the release workflow, installs it in throwaway
environments, updates it through the in-app updater from a fake GitHub, and
has agents use it like a user would. Nothing touches the Sheetopia
installation of the machine it runs on.

Two machines share the plan and run it independently:

| Host | Platforms | Environments | Extra |
|---|---|---|---|
| Mac (Apple Silicon) | macOS, iOS | tart macOS VM (no Xcode), headless iOS simulators (phone, tablet) | signed .dmg via act on the Mac itself |
| Linux (x86_64) | Linux, Android | Ubuntu 24.04 + Xfce desktop container (VNC), KVM Android emulator | ubuntu jobs via act natively, **full feature suite** |

## What a run does

1. **Prepare**: snapshot `test-plan.yaml`, generate the demo library fresh
   (`tool/demo_library/build.py --now <run start>`), create test fixtures,
   stage the working tree (the build under test, an imaginary next version
   with a bumped version number and test upgrade messages and, if a test
   needs it, a plain version bumped once more without upgrade messages),
   download the previous release.
   Uncommitted changes are included; `build.local_packages` are vendored in.
2. **Build**: `.github/workflows/release.yml` through act (under act the macOS
   job signs with the login keychain's identity without touching keychains,
   and notarization, uploads and attestation are skipped), plus the iOS simulator
   build (Mac) and the Linux profile build with the driver extension
   (`app/main_e2e.dart`, Linux).
3. **Test**, one chain per platform: the orchestrator provisions the
   environment, then agents run
   setup (import demo library, baseline export) →
   old→new update (previous release → build under test, *disabled until a
   release supports the GitHub URL override*) →
   platform features (real input and system UI) →
   feature suite (Linux only, driver build) →
   new→next update →
   upgrade message scenarios (each one more new→next update). The state
   after setup is snapshotted and restored before every later agent, each of
   which gets only `run.tests_per_agent` tests. Teardown is scripted.
4. **Report**: `runs/<id>/report.html` and `results.json`, generated from the
   result files.

Agents operate the screen through an MCP server (`harness/bin/mcp.dart`):
every action returns a small screenshot, `batch` runs several with one.
Their system prompt is a short base plus the guides the step needs (no
Claude Code default prompt, settings or memory), with a 5 minute prompt
cache. On the usage limit they wait for the reset and resume their session.

## Running it

Easiest: `follow tool/test/START.md`. The agent asks which parts to run.

Manually, from the repository root, with a unique run id:

```sh
tool/test/scripts/tool.sh e2e 2026-10-14_1700
```

Override plan values for one run with `--set`, e.g.
`--set phases.feature_suite.enabled=false --set platforms.ios.enabled=false`.
The agents are headless `claude -p` sessions (`--permission-mode`, default
`auto`, `--model`, default `sonnet`, `--effort`, default `medium`, `--max-turns`,
default 200, `--agent-timeout` in minutes per session, default 90). Progress: `runs/<id>/logs/orchestrator.log`,
transcripts: `runs/<id>/agents/`.

Continue an unfinished run (keeps builds and finished steps):

```sh
tool/test/scripts/tool.sh e2e 2026-10-14_1700 --resume
```

A full run takes hours and spawns roughly 22 (Mac) to 50 (Linux) agents.

## Setting up a machine

1. Usual Flutter development setup (Flutter, Xcode on the Mac; Android SDK
   with cmdline-tools, JDK and Docker usable without sudo, `/dev/kvm` on
   Linux).
2. `tool/test/scripts/prereqs.sh` installs the rest and builds the base images
   (Mac: act, node, tart, sendmidi, axe, lilypond and a ~30 GB macOS VM; Linux: act,
   jq, lilypond, the Android x86_64 image, the desktop image and the
   `snd-virmidi` module, which needs sudo once).
   `prereqs.sh --check` only reports.
3. Mac: copy `local.env.example` to `local.env` (gitignored) and fill in the
   name of the Developer ID identity in the login keychain (codesign asks
   once for access). Linux needs nothing: Android is signed with
   `android/key.properties` and the keystore it points to.

## Editing what is tested

`test-plan.yaml` is the only file to edit for that:

- `platform_features`: everything that goes through the OS, the embedder or a
  platform plugin, run on every listed platform (an `excluded` note says why a
  platform is missing),
- `feature_suite`: the app's own logic, once, on Linux,
- `update_checks`: what both update tests verify,
- `upgrade_messages`: upgrade message scenarios, one agent each,
- `phases`, `platforms`: switch parts on and off.

Tests are prose for the agents: what to do and what must be true afterwards.

## Layout

| Path | Purpose |
|---|---|
| `harness/bin/e2e.dart` | the orchestrator (`tool.sh e2e`) |
| `test-plan.yaml` | what is tested |
| `guides/` | how agents operate each environment, update procedure |
| `scripts/` | bash: prepare, stage, build, environments, fake GitHub, fixtures |
| `harness/` | Dart tools: `mcp` (agents' screen tools), `drive` (driver client), `vnc`, `fake_github`, `export_diff`, `plan` |
| `app/main_e2e.dart` | app entry point with the flutter_driver extension |
| `linux/` | the Linux desktop container image |
| `runs/` | run directories (gitignored) |

The update tests point the app at the fake GitHub with
`SHEETOPIA_GITHUB_API_URL` / `SHEETOPIA_GITHUB_WEB_URL` (Android: system
properties `debug.sheetopia.github_api_url` / `_web_url`), supported by
flutter_system_integration.

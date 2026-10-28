// Runs an E2E test run of Sheetopia on this host: prepare, build, one chain
// of headless Claude Code agents per platform, report. See tool/test/README.md.
//
//   tool/test/scripts/tool.sh e2e <run id> [--set path=value]...
//   tool/test/scripts/tool.sh e2e <run id> --resume
//
// Run it from the repository root. --resume continues an existing run: it
// keeps the builds and every finished step and reruns the rest.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

const _resultSchema = {
  'type': 'object',
  'properties': {
    'environmentOk': {'type': 'boolean', 'description': 'false if the environment/app is unusable for the following steps'},
    'results': {
      'type': 'array',
      'items': {
        'type': 'object',
        'properties': {
          'id': {'type': 'string'},
          'status': {
            'type': 'string',
            'enum': ['pass', 'fail', 'blocked', 'skipped'],
          },
          'summary': {'type': 'string'},
          'evidence': {
            'type': 'array',
            'items': {'type': 'string'},
          },
        },
        'required': ['id', 'status', 'summary'],
      },
    },
    'issues': {
      'type': 'array',
      'items': {
        'type': 'object',
        'properties': {
          'title': {'type': 'string'},
          'severity': {
            'type': 'string',
            'enum': ['critical', 'major', 'minor', 'cosmetic'],
          },
          'testId': {'type': 'string'},
          'steps': {'type': 'string'},
          'expected': {'type': 'string'},
          'actual': {'type': 'string'},
          'evidence': {
            'type': 'array',
            'items': {'type': 'string'},
          },
        },
        'required': ['title', 'severity', 'steps', 'expected', 'actual'],
      },
    },
    'notes': {'type': 'string', 'description': 'state the next step needs to know (installed version, fake GitHub URL, quirks)'},
  },
  'required': ['environmentOk', 'results', 'issues', 'notes'],
};

const _guides = {
  'macos': 'tool/test/guides/macos.md',
  'ios': 'tool/test/guides/ios.md',
  'linux': 'tool/test/guides/linux.md',
  'android': 'tool/test/guides/android.md',
};

const _envScripts = {
  'macos': 'macos_vm.sh',
  'ios': 'ios_sim.sh',
  'linux': 'linux_env.sh',
  'android': 'android.sh',
};

// Replaces Claude Code's default system prompt, which costs ~6k tokens on
// every request. The guides follow it, so agents of one kind share its cache.
const _systemBase =
    'You run headless inside an automated E2E run of Sheetopia, a sheet music app, nobody reads or answers questions until it is over. '
    'Your working directory is the repository root, Bash commands start there. '
    'Keep your messages to a few words between tool calls: every token in your context is re-read on every later request. '
    'Your session ends as soon as you reply without a tool call, so never stop to wait for background work. '
    'Wait for long commands with blocking checks (a loop that polls for completion within the Bash timeout, repeated as often as needed) until they are done. '
    'Verify that things behave as the test describes and report what you observe with evidence. '
    "Don't investigate root causes or read app source to explain failures. "
    'On the host, only create or change files inside the run directory (temporary files in its scratch/), never anywhere else (the repository, the home directory, /tmp). '
    'Files inside test environments (container, VM, emulator, simulator) are fine.';

const _resumePrompt =
    'Your session was interrupted (usage limit or API error) and has been resumed. The environment is as you left it, '
    'but time has passed: take a screenshot to see where you are, then continue the remaining tests and finish with the structured result.';

// The built-in tools the agents need. Everything else only adds context.
const _agentTools = 'Bash';

// Guide sections a step doesn't need, by guide file and step kind.
const _skippedSections = {
  'linux.md': {
    AgentKind.platform: ['Feature suite: the E2E driver build'],
    AgentKind.update: ['Feature suite: the E2E driver build'],
  },
};

enum AgentKind { build, platform, suite, update }

String _systemPrompt(AgentKind kind, String? platform) {
  final guides = [
    if (kind != AgentKind.build) 'common.md',
    if (platform != null && kind != AgentKind.build) p.basename(_guides[platform]!),
    if (kind == AgentKind.update) 'update.md',
  ];
  return [
    _systemBase,
    if (guides.isNotEmpty) 'The guides of this run follow (tool/test/guides/, no need to read them again).',
    for (final g in guides) _guideText(g, _skippedSections[g]?[kind] ?? const []),
  ].join('\n\n');
}

String _guideText(String file, List<String> skipped) {
  final text = File(p.join(_repo, 'tool', 'test', 'guides', file)).readAsStringSync();
  final sections = text.split(RegExp(r'^(?=## )', multiLine: true));
  return [
    '<guide file="$file">',
    for (final s in sections)
      if (!skipped.any((h) => s.startsWith('## $h'))) s.trimRight(),
    '</guide>',
  ].join('\n');
}

typedef Json = Map<String, dynamic>;

late final String _repo;
late final ArgResults _options;
final _logBuffer = StringBuffer();
File? _logFile;
String? _agentDir;
String? _mcpPath;

// Written synchronously, so the last line before exit() isn't lost.
void log(String message) {
  final line = '[${DateTime.now().toIso8601String().substring(11, 19)}] $message';
  stdout.writeln(line);
  if (_logFile != null) {
    _logFile!.writeAsStringSync('$line\n', mode: FileMode.append);
  } else {
    _logBuffer.writeln(line);
  }
}

Never fail(String message) {
  log('error: $message');
  exit(1);
}

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addMultiOption('set', splitCommas: false, help: 'plan override path=value, repeatable')
    ..addFlag('resume', negatable: false, help: 'continue an existing run, rerunning unfinished steps')
    ..addOption('permission-mode', defaultsTo: 'auto', help: 'permission mode of the agents')
    ..addOption('model', defaultsTo: 'sonnet', help: 'model of the agents')
    ..addOption('effort', defaultsTo: 'medium', help: 'effort level of the agents')
    ..addOption('max-turns', defaultsTo: '200', help: 'turns after which an agent is stopped')
    ..addOption('agent-timeout', defaultsTo: '90', help: 'minutes after which an agent session is killed');
  try {
    _options = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('${e.message}\nusage: e2e <run id> [--set path=value]... | e2e <run id> --resume\n${parser.usage}');
    exit(64);
  }
  final runId = _options.rest.length == 1 ? _options.rest.single : '';
  if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(runId)) {
    stderr.writeln('usage: e2e <run id like 2026-10-14_1700> [--set path=value]... | --resume\n${parser.usage}');
    exit(64);
  }
  final resume = _options.flag('resume');
  if (resume && _options.multiOption('set').isNotEmpty) {
    stderr.writeln('--set does not apply to --resume, the run keeps its plan');
    exit(64);
  }
  _repo = (await Process.run('git', ['rev-parse', '--show-toplevel'])).stdout.toString().trim();
  if (_repo.isEmpty) fail('not inside the repository');

  // --- Prepare ---------------------------------------------------------------

  log('phase Prepare');
  final Json run;
  if (resume) {
    final file = File(p.join(_repo, 'tool', 'test', 'runs', runId, 'run.json'));
    if (!file.existsSync()) fail('no run $runId to resume');
    run = jsonDecode(file.readAsStringSync());
  } else {
    final sets = _options.multiOption('set');
    final prepare = await _script('tool/test/scripts/prepare.sh', [runId, for (final s in sets) ...['--set', s]]);
    if (prepare.exitCode != 0) fail('prepare.sh failed (exit ${prepare.exitCode})');
    run = jsonDecode(prepare.stdout);
  }
  final runDir = run['runDir'] as String;
  _logFile = File(p.join(runDir, 'logs', 'orchestrator.log'))..writeAsStringSync('$_logBuffer', mode: FileMode.append);
  _agentDir = p.join(runDir, 'agents');
  Directory(_agentDir!).createSync(recursive: true);
  Directory(p.join(runDir, 'results')).createSync(recursive: true);
  if (resume) log('resuming run $runId');

  final planOut = await _script('tool/test/scripts/tool.sh', ['plan', '--plan', p.join(runDir, 'test-plan.yaml'), 'json']);
  if (planOut.exitCode != 0) fail('reading the plan failed');
  final Json plan = jsonDecode(planOut.stdout);

  final phases = List<String>.from(run['phases'] ?? const []);
  bool enabled(String name) => phases.contains(name);
  final platforms = List<String>.from(run['platforms'] ?? const []);
  final Json versions = run['versions'];
  log('run ${run['id']} on ${run['host']}: ${platforms.isEmpty ? 'no platforms' : platforms.join(', ')}; versions ${jsonEncode(versions)}');
  if (platforms.isEmpty) fail('no enabled platforms for host ${run['host']} in the plan');
  for (final w in run['warnings'] ?? const []) {
    log('warning: $w');
  }

  // --- Build -----------------------------------------------------------------

  log('phase Build');
  final summaryTsv = File(p.join(runDir, 'builds', 'summary.tsv'));
  // Failing unit tests and skipped builds are no reason to rebuild everything.
  bool builtOk() =>
      summaryTsv.existsSync() &&
      !summaryTsv.readAsLinesSync().map((l) => l.split('\t')).any((f) => f.length > 2 && f[1] != 'test' && f[2].startsWith('FAILED'));
  if (!enabled('build')) {
    log('build phase disabled');
  } else if (resume && builtOk()) {
    log('keeping the builds of the run');
  } else {
    log('build.sh running, logs in $runDir/logs/');
    final build = await _script('tool/test/scripts/build.sh', [runDir], outputFile: p.join(runDir, 'logs', 'build.log'));
    final tsv = summaryTsv.existsSync() ? summaryTsv.readAsStringSync().trim() : '(no summary.tsv)';
    var buildSummary = '$tsv\n\nFiles:\n${_buildFiles(runDir).join('\n')}';
    if (build.exitCode != 0) {
      log('build.sh failed (exit ${build.exitCode}), asking an agent for the causes');
      final report = await agent('''Build of the Sheetopia E2E run $runDir for this host (${run['host']}) has finished with failures (tool/test/scripts/build.sh $runDir, output in $runDir/logs/build.log).

Return a short plain text report:
- the content of $runDir/builds/summary.tsv,
- for every FAILED step the cause from its log (read the end of the log, find the first real error),
- the files in $runDir/releases/*/ and $runDir/builds/current/ (one line each).
Don't try to fix build failures in the repository. You may re-run a single failed step once if the failure is clearly transient (network), with build.sh --stage <s> --only <part>, and report the outcome.''', label: 'build', kind: AgentKind.build);
      if (report is String) buildSummary = report;
    }
    log(buildSummary.split('\n').take(12).join('\n'));
  }

  // --- Test ------------------------------------------------------------------

  log('phase Test');
  final mcp = await _script('tool/test/scripts/tool.sh', ['mcp', '--path']);
  if (mcp.exitCode != 0) fail('compiling the MCP server failed');
  _mcpPath = mcp.stdout.trim();

  final current = versions['current'];
  final next = versions['next'];
  final plain = versions['plain'];
  final previous = versions['previous'];
  final perAgent = max(1, ((plan['run'] ?? const {})['tests_per_agent'] as num?)?.toInt() ?? 3);

  String common(String platform) => '''You are an E2E tester of Sheetopia (a sheet music app) on $platform. Follow the guides in your system prompt.
Run directory: RUN=$runDir (run.json there: versions ${jsonEncode(versions)}).
Builds: $runDir/releases/<v-version>/ (release assets) and $runDir/builds/current/.
Evidence screenshots go to $runDir/screenshots/$platform/ (the screen tools' save_as does that).''';

  String testList(List<Json> tests) => tests.map((t) => '- ${t['id']}: ${t['test']}').join('\n');

  bool isEnabled(Json t) => t['enabled'] != false;
  final updatePlatforms = List<String>.from(plan['update_platforms'] ?? const []);
  List<Json> platformTests(String platform) => [
    for (final Json t in plan['platform_features'] ?? const [])
      if (isEnabled(t) && (t['platforms'] ?? const []).contains(platform)) t,
  ];
  final updateChecks = [
    for (final Json t in plan['update_checks'] ?? const [])
      if (isEnabled(t)) t,
  ];
  List<Json> upgradeMessageTests(String platform) => [
    for (final Json t in plan['upgrade_messages'] ?? const [])
      if (isEnabled(t) && (t['platforms'] ?? const ['linux']).contains(platform)) t,
  ];

  List<List<Json>> chunks(List<Json> tests) => [
    for (var i = 0; i < tests.length; i += perAgent) tests.sublist(i, min(tests.length, i + perAgent)),
  ];

  Future<_Chain> platformChain(String platform) async {
    final update = updatePlatforms.contains(platform);
    final oldToNew = update && enabled('old_to_new_update') && previous != null && previous.toString().isNotEmpty;
    final env = _Env(platform, runDir);
    const restored =
        'The orchestrator restored the starting state of this platform (see "Starting state" in your platform guide), the app is not running. '
        'You need not clean up afterwards: the next step starts from the restored state again.';

    final steps = <_StepSpec>[
      _StepSpec('setup', '''Prepare the starting state of the $platform environment. The orchestrator already brought it up, installed ${oldToNew ? 'the PREVIOUS release $previous' : 'the build under test v$current'} and copied the test files (see "Starting state" in your platform guide for where things are).
- start the app, get through first-start prompts, import the run's demo library through Settings > Import/Export > Import (the user way, native file dialog),
- change the settings listed in the update guide ("Preparing the starting state") and take the baseline export as described there, saved as $runDir/results/$platform-${oldToNew ? 'old-to-new' : 'setup'}-before.zip${update ? '' : ' (export via the share sheet / Files where there is no save dialog)'}.
Return environmentOk=false only if the environment or app can't be used at all. Report no test results (empty list) unless something you did is clearly broken, then add an issue. In notes: only what the following agents need that the guides don't say, in a few lines.''', const [], AgentKind.update, restore: false),
      if (oldToNew)
        _StepSpec('old-to-new-update', 'Update the installed previous release $previous to v$current with the in-app updater, following the update guide (old -> new).', updateChecks, AgentKind.update, restore: false),
      if (enabled('platform_features'))
        for (final (i, tests) in chunks(platformTests(platform)).indexed)
          _StepSpec('platform-features-${i + 1}', '$restored\n\nRun these platform tests with the platform\'s real input and system UI. The app under test is v$current.', tests, AgentKind.platform),
      if (platform == 'linux' && enabled('feature_suite'))
        for (final Json area in plan['feature_suite'] ?? const [])
          for (final (i, tests) in chunks([
            for (final Json t in area['tests'] ?? const [])
              if (isEnabled(t)) {'id': t['id'], 'test': _testText(t)},
          ]).indexed)
            _StepSpec(
              'feature-suite-${area['area'].toString().toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-')}-${i + 1}',
              '$restored\n\nFeature suite area "${area['area']}" with the E2E driver build (see "Feature suite: the E2E driver build" in the Linux guide): start it with linux_env.sh driver, it uses the release build\'s data. Pointer kinds named in a test\'s inputs must each be exercised.',
              tests,
              AgentKind.suite,
            ),
      if (update && enabled('new_to_next_update') && next != null && next.toString().isNotEmpty)
        _StepSpec('new-to-next-update', '$restored\n\nThe installed app is the release build v$current. Take a fresh baseline export, then update to the imaginary next release v$next with the in-app updater, following the update guide (new -> next).', [
          for (final t in updateChecks) {'id': '${t['id']}.next', 'test': t['test']},
        ], AgentKind.update),
      if (enabled('upgrade_messages') && next != null && next.toString().isNotEmpty)
        for (final t in upgradeMessageTests(platform))
          if (t['plain_build'] != true)
            _StepSpec(
              t['id'].toString().replaceAll(RegExp('[^a-z0-9]+'), '-'),
              '$restored\n\nThe installed app is the release build v$current. Run this upgrade messages scenario, upgrading to the imaginary next release v$next as the test says (the update guide has the procedure). Its test messages are in $runDir/upgrade-messages-next.json.',
              [t],
              AgentKind.update,
            )
          else if (plain != null && plain.toString().isNotEmpty)
            _StepSpec(
              t['id'].toString().replaceAll(RegExp('[^a-z0-9]+'), '-'),
              '$restored\n\nThe installed app is the release build v$current. Run this upgrade messages scenario, upgrading to the imaginary plain release v$plain (no upgrade messages, assets in $runDir/releases/v$plain/) as the test says (the update guide has the procedure).',
              [t],
              AgentKind.update,
            ),
    ];

    final results = <String, Json>{};
    for (final s in steps) {
      final file = File(p.join(runDir, 'results', '$platform-${s.name}.json'));
      if (!file.existsSync()) continue;
      final Json r;
      try {
        r = jsonDecode(file.readAsStringSync());
      } on FormatException {
        log('$platform: ignoring the unreadable ${p.basename(file.path)}, rerunning ${s.name}');
        continue;
      }
      if (r['rerun'] != true) results[s.name] = r;
    }
    _Chain finish() => (platform: platform, steps: [for (final s in steps) if (results[s.name] != null) (name: s.name, result: results[s.name]!)]);
    void save(String name, Json result) {
      results[name] = result;
      File(p.join(runDir, 'results', '$platform-$name.json')).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(result));
    }

    void blockRest(String reason) {
      for (final s in steps) {
        if (!results.containsKey(s.name)) save(s.name, _blocked(s.tests, reason));
      }
    }

    if (steps.every((s) => results.containsKey(s.name))) {
      log('$platform: all steps finished earlier');
      return finish();
    }

    try {
      // The starting state: a snapshot after setup (and old->new), recreated
      // from scratch if any of it is missing.
      final startDone = results.containsKey('setup') && (!oldToNew || results.containsKey('old-to-new-update'));
      if (startDone && env.hasSnapshot('start')) {
        if (!await env.recover()) {
          blockRest('the $platform environment could not be provisioned, see logs/env-$platform.log');
          return finish();
        }
      } else {
        results.remove('setup');
        results.remove('old-to-new-update');
        await env.run(['down', runDir], quiet: true);
        if (!await env.run(['provision', runDir, if (oldToNew) previous.toString()])) {
          blockRest('the $platform environment could not be provisioned, see logs/env-$platform.log');
          return finish();
        }
      }

      final setupNotes = (results['setup']?['notes'] ?? '').toString();
      var notes = setupNotes;
      for (final s in steps) {
        if (results.containsKey(s.name)) continue;
        if (s.restore && !await env.run(['snapshot', runDir, 'restore', 'start']) && !await env.recover()) {
          blockRest('the $platform environment could not be restored, see logs/env-$platform.log');
          return finish();
        }
        final r = await agent('''${common(platform)}

Step: ${s.name}
Notes from setup: ${notes.isEmpty ? '(none)' : notes}

${s.prompt}${s.tests.isEmpty ? '' : '\n\nTests (report every id exactly once):\n${testList(s.tests)}'}''', label: '$platform-${s.name}', kind: s.kind, platform: platform, schema: _resultSchema);
        final Json result = r is Json ? r : _blocked(s.tests, 'the agent failed, see agents/$platform-${s.name}.jsonl');
        save(s.name, result);
        if (!s.restore) {
          if (result['environmentOk'] != true) {
            blockRest('${s.name} left the environment unusable: ${result['notes']}');
            return finish();
          }
          if (s.name == 'setup') notes = (result['notes'] ?? '').toString();
          final last = steps.lastWhere((x) => !x.restore).name;
          if (s.name == last && !await env.run(['snapshot', runDir, 'save', 'start'])) {
            blockRest('saving the starting state failed, see logs/env-$platform.log');
            return finish();
          }
        } else if (result['environmentOk'] != true && !await env.recover()) {
          blockRest('the $platform environment broke in ${s.name} and could not be recreated');
          return finish();
        }
      }
      return finish();
    } catch (e, stack) {
      log('$platform: orchestrator error: $e\n$stack');
      blockRest('orchestrator error: $e');
      return finish();
    } finally {
      await env.teardown();
    }
  }

  final Json runSettings = plan['run'] ?? const {};
  final limit = max(1, (runSettings['max_parallel_environments'] as num?)?.toInt() ?? 1);
  final queue = [...platforms];
  final chains = <_Chain>[];
  Future<void> worker() async {
    while (queue.isNotEmpty) {
      chains.add(await platformChain(queue.removeAt(0)));
    }
  }

  await Future.wait([for (var i = 0; i < min(limit, platforms.length); i++) worker()]);
  chains.sort((a, b) => platforms.indexOf(a.platform).compareTo(platforms.indexOf(b.platform)));

  // --- Report ----------------------------------------------------------------

  log('phase Report');
  final counts = <String, int>{};
  final issues = <Json>[];
  for (final chain in chains) {
    // One result per test and platform, the last one reported, as in the report.
    final statuses = {
      for (final s in chain.steps)
        for (final Json r in s.result['results'] ?? const []) r['id'].toString(): r['status'].toString(),
    };
    for (final status in statuses.values) {
      counts.update(status, (n) => n + 1, ifAbsent: () => 1);
    }
    for (final s in chain.steps) {
      for (final Json i in s.result['issues'] ?? const []) {
        issues.add({...i, 'platform': chain.platform, 'step': s.name});
      }
    }
  }
  log('results: ${jsonEncode(counts)}, issues: ${issues.length}');
  final testTexts = <String, String>{
    for (final Json t in [
      ...?plan['update_checks'],
      ...?plan['upgrade_messages'],
      ...?plan['platform_features'],
      for (final Json area in plan['feature_suite'] ?? const []) ...?area['tests'],
    ])
      t['id'].toString(): _testText(t),
    for (final Json t in plan['update_checks'] ?? const []) '${t['id']}.next': t['test'].toString(),
  };
  final reportPath = _writeReport(runDir, run, chains, counts, issues, testTexts);

  final summary = {
    'run': run['id'],
    'host': run['host'],
    'counts': counts,
    'issues': issues.length,
    'rerunnable': chains.any((c) => c.steps.any((s) => s.result['rerun'] == true)),
    'report': reportPath,
  };
  File(p.join(runDir, 'summary.json')).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(summary));
  log('done: ${jsonEncode(summary)}');
  exit(0);
}

typedef _Step = ({String name, Json result});
typedef _Chain = ({String platform, List<_Step> steps});

class _StepSpec {
  final String name;
  final String prompt;
  final List<Json> tests;
  final AgentKind kind;

  /// Starts from the restored starting state.
  final bool restore;

  const _StepSpec(this.name, this.prompt, this.tests, this.kind, {this.restore = true});
}

Json _blocked(List<Json> tests, String reason) => {
  'environmentOk': false,
  'rerun': true,
  'results': [
    for (final t in tests) {'id': t['id'], 'status': 'blocked', 'summary': reason},
  ],
  'issues': <Json>[],
  'notes': reason,
};

/// One platform's environment, operated through its script.
class _Env {
  final String platform;
  final String runDir;

  _Env(this.platform, this.runDir);

  bool hasSnapshot(String name) =>
      File(p.join(runDir, 'snapshots', '${platform == 'ios' ? 'ios-phone' : platform}-$name.tar')).existsSync();

  Future<bool> run(List<String> args, {bool quiet = false}) async {
    final r = await _script('tool/test/scripts/${_envScripts[platform]}', args, outputFile: p.join(runDir, 'logs', 'env-$platform.log'));
    if (r.exitCode != 0 && !quiet) log('$platform: ${_envScripts[platform]} ${args.first} ${args.skip(2).join(' ')} failed (exit ${r.exitCode})');
    return r.exitCode == 0;
  }

  /// A fresh environment with the build under test and the starting state.
  Future<bool> recover() async {
    log('$platform: recreating the environment from the starting state');
    await run(['down', runDir], quiet: true);
    return await run(['provision', runDir]) && await run(['snapshot', runDir, 'restore', 'start']);
  }

  Future<void> teardown() async {
    log('$platform: teardown');
    final logs = p.join(runDir, 'logs', platform);
    Directory(logs).createSync(recursive: true);
    // The app data holds the app's logs.
    await run(['snapshot', runDir, 'save', 'final'], quiet: true);
    switch (platform) {
      case 'linux':
        await run(['pull', runDir, '/home/sheetopia/e2e/app.log', logs], quiet: true);
      case 'macos':
        await run(['pull', runDir, '/Users/admin/Library/Logs/Sheetopia/update.log', logs], quiet: true);
        await run(['pull', runDir, '/Users/admin/e2e/app.log', logs], quiet: true);
      case 'android':
        await _script('tool/test/scripts/android.sh', ['adb', runDir, 'logcat', '-d'], outputFile: p.join(logs, 'logcat.txt'));
    }
    await _script('tool/test/scripts/fake_github.sh', ['stop', runDir, platform]);
    await run(['down', runDir], quiet: true);
    if (platform == 'ios') await run(['down', runDir, '--sim', 'tablet'], quiet: true);
  }
}

List<String> _buildFiles(String runDir) => [
  for (final dir in [
    if (Directory(p.join(runDir, 'releases')).existsSync())
      ...Directory(p.join(runDir, 'releases')).listSync().whereType<Directory>().map((d) => d.path),
    p.join(runDir, 'builds', 'current'),
  ])
    if (Directory(dir).existsSync())
      for (final e in Directory(dir).listSync()) p.relative(e.path, from: runDir),
];

Future<({int exitCode, String stdout})> _script(String script, List<String> args, {String? outputFile}) async {
  final process = await Process.start(p.join(_repo, script), args, workingDirectory: _repo);
  final out = StringBuffer();
  final sink = outputFile == null ? null : (File(outputFile)..parent.createSync(recursive: true)).openWrite(mode: FileMode.append);
  sink?.writeln('\$ ${p.basename(script)} ${args.join(' ')}');
  final done = [
    process.stdout.transform(utf8.decoder).forEach(sink == null ? out.write : sink.write),
    process.stderr.transform(utf8.decoder).forEach(sink == null ? stderr.write : sink.write),
  ];
  final exitCode = await process.exitCode;
  await Future.wait(done);
  await sink?.close();
  return (exitCode: exitCode, stdout: out.toString());
}

// --- Agents -------------------------------------------------------------------

typedef _Attempt = ({int exitCode, Json? result, String? session, int toolUses, DateTime? limitResetsAt, bool usageLimit});

// Runs one headless Claude Code agent. Returns the structured output with a
// schema, the final text without, or null if the agent failed. Waits out
// usage limits and resumes the session afterwards.
Future<Object?> agent(String prompt, {required String label, required AgentKind kind, String? platform, Map<String, Object?>? schema}) async {
  final name = label.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  final started = DateTime.now();
  log('agent $name started (transcript agents/$name.jsonl)');
  String? session;
  var toolUses = 0;
  var cost = 0.0;
  var turns = 0;
  var limitWaits = 0, errorRetries = 0;
  while (true) {
    final a = await _attempt(name, session != null && toolUses > 0 ? _resumePrompt : prompt,
        resume: toolUses > 0 ? session : null, system: _systemPrompt(kind, platform), platform: platform, schema: schema);
    session = a.session ?? session;
    toolUses += a.toolUses;
    cost += (a.result?['total_cost_usd'] as num?)?.toDouble() ?? 0;
    turns += (a.result?['num_turns'] as num?)?.toInt() ?? 0;
    final value = a.result?[schema != null ? 'structured_output' : 'result'];
    if (a.exitCode == 0 && a.result != null && a.result!['is_error'] != true && value != null) {
      log('agent $name done after ${DateTime.now().difference(started).inMinutes} min, $turns turns, \$${cost.toStringAsFixed(2)}, session $session');
      return value;
    }
    if (a.usageLimit && limitWaits++ < 12) {
      final until = (a.limitResetsAt ?? DateTime.now().add(const Duration(minutes: 30))).add(const Duration(minutes: 1));
      log('agent $name hit the usage limit, waiting until ${until.toIso8601String().substring(11, 16)}');
      await Future<void>.delayed(until.difference(DateTime.now()) > Duration.zero ? until.difference(DateTime.now()) : Duration.zero);
      continue;
    }
    if (a.result?['api_error_status'] != null && errorRetries++ < 3) {
      log('agent $name: API error ${a.result!['api_error_status']}, retrying in ${errorRetries * 2} min');
      await Future<void>.delayed(Duration(minutes: errorRetries * 2));
      continue;
    }
    log('agent $name FAILED after ${DateTime.now().difference(started).inMinutes} min '
        '(exit ${a.exitCode}, ${a.result?['subtype'] ?? 'no result'}, ${a.result?['api_error'] ?? ''} session ${session ?? '?'})');
    return null;
  }
}

Future<_Attempt> _attempt(String name, String prompt, {required String system, String? resume, String? platform, Map<String, Object?>? schema}) async {
  final process = await Process.start('claude', [
    '-p',
    '--output-format', 'stream-json',
    '--verbose',
    '--permission-mode', _options.option('permission-mode')!,
    '--system-prompt', system,
    '--setting-sources', '',
    '--name', 'e2e $name',
    '--model', _options.option('model')!,
    '--effort', _options.option('effort')!,
    '--max-turns', _options.option('max-turns')!,
    '--tools', _agentTools,
    '--disable-slash-commands',
    '--strict-mcp-config',
    if (platform != null) ...[
      '--mcp-config',
      jsonEncode({
        'mcpServers': {
          'e2e': {
            'command': _mcpPath,
            'args': ['--run', p.dirname(_agentDir!), '--platform', platform],
          },
        },
      }),
      '--allowedTools', 'mcp__e2e',
    ],
    if (resume != null) ...['--resume', resume],
    if (schema != null) ...['--json-schema', jsonEncode(schema)],
  ], workingDirectory: _repo, environment: {
    // Requests come seconds apart, the default 1h cache only makes writes dearer.
    'CLAUDE_CODE_PROMPT_CACHE_TTL': '5m',
    'CLAUDE_CODE_DISABLE_AUTO_MEMORY': '1',
  });
  process.stdin.write(prompt);
  await process.stdin.close();
  final timeout = Duration(minutes: int.parse(_options.option('agent-timeout')!));
  final killer = Timer(timeout, () {
    log('agent $name: killed after ${timeout.inMinutes} min');
    process.kill();
  });

  final transcript = File(p.join(_agentDir!, '$name.jsonl')).openWrite(mode: FileMode.append);
  final errors = File(p.join(_agentDir!, '$name.stderr')).openWrite(mode: FileMode.append);
  final stderrDone = process.stderr.pipe(errors);
  Json? result;
  String? session;
  var toolUses = 0;
  DateTime? resetsAt;
  var usageLimit = false;
  await for (final line in process.stdout.transform(utf8.decoder).transform(const LineSplitter())) {
    transcript.writeln(line);
    final Json event;
    try {
      event = jsonDecode(line);
    } on FormatException {
      continue;
    }
    session = event['session_id'] as String? ?? session;
    if (event['type'] == 'result') result = event;
    if (event['type'] == 'assistant') {
      for (final c in (event['message']?['content'] as List?) ?? const []) {
        if (c is Map && c['type'] == 'tool_use') toolUses++;
      }
    }
    if (event['api_error'] == 'usage_limit_reached') usageLimit = true;
    final resets = (event['api_error_params']?['rate_limit_info'] as Map?)?['resetsAt'];
    if (resets is num) {
      usageLimit = true;
      resetsAt = DateTime.fromMillisecondsSinceEpoch(resets.toInt() * 1000);
    }
  }
  final exitCode = await process.exitCode;
  killer.cancel();
  await stderrDone;
  await transcript.close();
  return (exitCode: exitCode, result: result, session: session, toolUses: toolUses, limitResetsAt: resetsAt, usageLimit: usageLimit);
}

// --- Report -------------------------------------------------------------------

String _testText(Json t) => t['inputs'] != null ? '${t['test']} [inputs: ${(t['inputs'] as List).join(', ')}]' : t['test'].toString();

String _esc(Object? s) => const HtmlEscape().convert('${s ?? ''}');

String _writeReport(String runDir, Json run, List<_Chain> chains, Map<String, int> counts, List<Json> issues, Map<String, String> testTexts) {
  final summaryTsv = File(p.join(runDir, 'builds', 'summary.tsv'));
  final buildRows = summaryTsv.existsSync()
      ? [for (final l in summaryTsv.readAsLinesSync()) if (l.trim().isNotEmpty) l.split('\t')]
      : <List<String>>[];
  File(p.join(runDir, 'results.json')).writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
    'run': run,
    'build': [for (final r in buildRows) {'stage': r.first, 'step': r.length > 1 ? r[1] : '', 'status': r.last}],
    'steps': [
      for (final c in chains)
        for (final s in c.steps) {'platform': c.platform, 'step': s.name, ...s.result},
    ],
  }));

  String evidence(Object? e) {
    final path = e.toString();
    final abs = p.isAbsolute(path) ? path : p.join(_repo, path);
    final rel = p.isWithin(runDir, abs) ? p.relative(abs, from: runDir) : (File(p.join(runDir, path)).existsSync() ? path : null);
    if (rel == null) return '<code>${_esc(path)}</code>';
    if (RegExp(r'\.(png|jpe?g)$', caseSensitive: false).hasMatch(rel)) {
      return '<a href="${_esc(rel)}"><img loading="lazy" src="${_esc(rel)}" alt="${_esc(rel)}"></a>';
    }
    return '<a href="${_esc(rel)}">${_esc(rel)}</a>';
  }

  final platforms = [for (final c in chains) c.platform];
  final matrix = <String, Map<String, Json>>{};
  for (final c in chains) {
    for (final s in c.steps) {
      for (final Json r in s.result['results'] ?? const []) {
        matrix.putIfAbsent(r['id'].toString(), () => {})[c.platform] = r;
      }
    }
  }
  final verdict = (counts['fail'] ?? 0) > 0
      ? '${counts['fail']} failed'
      : (counts['blocked'] ?? 0) > 0
          ? 'no failures, ${counts['blocked']} blocked'
          : 'all passed';
  const order = ['critical', 'major', 'minor', 'cosmetic'];
  final sorted = [...issues]..sort((a, b) => order.indexOf(a['severity'].toString()).compareTo(order.indexOf(b['severity'].toString())));
  final versions = (run['versions'] as Map?) ?? const {};

  final html = StringBuffer('''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>E2E ${_esc(run['id'])}</title>
<style>
:root { --bg: #fff; --fg: #1b1b1f; --muted: #5f6368; --line: #dadce0; --pass: #1e8e3e; --fail: #d93025; --blocked: #e37400; --skipped: #80868b; --card: #f6f7f9; }
@media (prefers-color-scheme: dark) { :root { --bg: #16171a; --fg: #e8eaed; --muted: #9aa0a6; --line: #3c4043; --pass: #5bb974; --fail: #f28b82; --blocked: #fdd663; --skipped: #9aa0a6; --card: #1f2024; } }
body { background: var(--bg); color: var(--fg); font: 15px/1.5 system-ui, sans-serif; margin: 0 auto; padding: 16px; }
h1 { font-size: 1.4em; margin: 0 0 4px; } h2 { font-size: 1.15em; margin-top: 2em; border-bottom: 1px solid var(--line); }
.meta, .muted { color: var(--muted); } .verdict { font-size: 1.2em; font-weight: 600; margin: 12px 0; }
.scroll { overflow-x: auto; } table { border-collapse: collapse; width: 100%; } th, td { border-bottom: 1px solid var(--line); padding: 4px 8px; text-align: left; vertical-align: top; }
.pass { color: var(--pass); } .fail { color: var(--fail); } .blocked { color: var(--blocked); } .skipped { color: var(--skipped); }
td.status { white-space: nowrap; font-weight: 600; } td.test { min-width: 14em; max-width: 36em; } details summary { cursor: pointer; }
.issue { background: var(--card); border-radius: 8px; padding: 8px 12px; margin: 8px 0; }
.issue img { max-width: 220px; max-height: 220px; margin: 4px 4px 0 0; border: 1px solid var(--line); }
pre { white-space: pre-wrap; margin: 0; font: inherit; }
</style>
</head>
<body>
<h1>Sheetopia E2E run ${_esc(run['id'])}</h1>
<div class="meta">host ${_esc(run['host'])} &middot; commit ${_esc(run['commit'])}${run['uncommittedChanges'] == true ? ' + uncommitted changes' : ''} &middot; versions previous ${_esc(versions['previous'] == '' ? '-' : versions['previous'])}, current ${_esc(versions['current'])}, next ${_esc(versions['next'] == '' ? '-' : versions['next'])}, plain ${_esc((versions['plain'] ?? '') == '' ? '-' : versions['plain'])} &middot; started ${_esc(run['startedAt'])}</div>
<div class="verdict ${(counts['fail'] ?? 0) > 0 ? 'fail' : (counts['blocked'] ?? 0) > 0 ? 'blocked' : 'pass'}">${_esc(verdict)}</div>
<div class="muted">${[for (final s in ['pass', 'fail', 'blocked', 'skipped']) '${counts[s] ?? 0} $s'].join(' &middot; ')} &middot; ${issues.length} issues</div>
''');

  html.writeln('<h2>Build</h2><div class="scroll"><table><tr><th>Stage</th><th>Step</th><th>Status</th></tr>');
  for (final r in buildRows) {
    html.writeln('<tr><td>${_esc(r.first)}</td><td>${_esc(r.length > 2 ? r[1] : '')}</td><td class="status ${r.last == 'ok' ? 'pass' : 'fail'}">${_esc(r.last)}</td></tr>');
  }
  html.writeln('</table></div>');

  html.writeln('<h2>Results</h2><div class="scroll"><table><tr><th>Test</th>${platforms.map((pl) => '<th>${_esc(pl)}</th>').join()}</tr>');
  for (final MapEntry(key: id, value: row) in matrix.entries) {
    final text = testTexts[id];
    html.write(text == null ? '<tr><td>${_esc(id)}</td>' : '<tr><td class="test"><details><summary>${_esc(id)}</summary><pre>${_esc(text)}</pre></details></td>');
    for (final pl in platforms) {
      final r = row[pl];
      if (r == null) {
        html.write('<td class="muted">-</td>');
      } else {
        html.write('<td><details><summary class="${_esc(r['status'])}">${_esc(r['status'])}</summary><pre>${_esc(r['summary'])}</pre>'
            '${((r['evidence'] as List?) ?? const []).map(evidence).join(' ')}</details></td>');
      }
    }
    html.writeln('</tr>');
  }
  html.writeln('</table></div>');

  html.writeln('<h2>Issues</h2>');
  if (sorted.isEmpty) html.writeln('<p class="muted">None.</p>');
  for (final i in sorted) {
    html.writeln('''<div class="issue"><div><b class="${i['severity'] == 'critical' || i['severity'] == 'major' ? 'fail' : 'blocked'}">${_esc(i['severity'])}</b> ${_esc(i['title'])} <span class="muted">(${_esc(i['platform'])}, ${_esc(i['testId'] ?? i['step'])})</span></div>
<details><summary>Details</summary><p><b>Steps</b></p><pre>${_esc(i['steps'])}</pre><p><b>Expected</b></p><pre>${_esc(i['expected'])}</pre><p><b>Actual</b></p><pre>${_esc(i['actual'])}</pre></details>
<div>${((i['evidence'] as List?) ?? const []).map(evidence).join(' ')}</div></div>''');
  }

  html.writeln('<h2>Notes</h2>');
  for (final c in chains) {
    html.writeln('<h3>${_esc(c.platform)}</h3>');
    for (final s in c.steps) {
      if ((s.result['notes'] ?? '').toString().isEmpty) continue;
      html.writeln('<details><summary>${_esc(s.name)}${s.result['environmentOk'] == true ? '' : ' <span class="blocked">(environment not ok)</span>'}</summary><pre>${_esc(s.result['notes'])}</pre></details>');
    }
  }
  html.writeln('</body>\n</html>');
  final path = p.join(runDir, 'report.html');
  File(path).writeAsStringSync(html.toString());
  return path;
}

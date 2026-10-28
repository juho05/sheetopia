import 'driver.dart';
import 'library.dart';
import 'target.dart';
import 'util.dart';

class SceneContext {
  final AppDriver d;
  final Library library;
  final FormFactor formFactor;

  /// Logical size of the app.
  final List<double> size;

  SceneContext(this.d, this.library, this.formFactor, this.size);

  bool get desktop => const ['linux', 'macos'].contains(formFactor.id);

  /// Waits for PDF pages and thumbnails, which render after the UI settled.
  Future<void> ready() async {
    await d.call('settle', {'quietMs': 800, 'timeoutMs': 10000});
    await delay(1000);
    await d.call('settle', {'quietMs': 500, 'timeoutMs': 10000});
  }
}

class Scene {
  final String name;

  /// Light theme below the diagonal, dark above it.
  final bool lightAndDark;
  final Future<void> Function(SceneContext c) prepare;

  /// Undoes state that outlives the screen, e.g. library filters.
  final Future<void> Function(SceneContext c)? cleanup;

  const Scene(this.name, this.prepare, {this.lightAndDark = false, this.cleanup});
}

/// Renders every thumbnail once so the library scene doesn't wait for them.
Future<void> warmUp(AppDriver d) async {
  await d.go('/');
  await d.call('settle', {'quietMs': 2000, 'timeoutMs': 30000});
}

const _bach = 'Praeludium I in C, BWV 846';

/// The README motifs, in README order.
final scenes = <Scene>[
  Scene('library', (c) async {}, lightAndDark: true),
  Scene('filter', (c) async {
    if (await c.d.visible(text: 'Filter')) {
      await c.d.tap(text: 'Filter');
    } else {
      // Compact layouts show only the icon (Icons.filter_alt_outlined).
      final button = (await c.d.describe()).where((i) => i.icon == '0xf068').firstOrNull;
      if (button == null) throw ToolException('no filter button');
      await c.d.tapAt(button.center);
      await c.d.settle();
    }
    // The composer row is the only text field in the dialog.
    final composer = (await c.d.describe()).where((i) => i.type == 'field').firstOrNull;
    if (composer == null) throw ToolException('no composer field');
    await c.d.tapAt(composer.center);
    await c.d.settle();
    await c.d.type('Johann Sebastian Bach');
    await c.d.unfocus();
    await c.d.tap(tooltip: 'Select instrument');
    await c.d.type('Piano', submit: true);
    await c.d.tap(text: 'Add filter');
    await c.d.tap(text: 'Difficulty');
    await c.d.tap(tooltip: 'Easy');
    await c.d.tap(tooltip: 'Medium');
    await c.d.tap(text: 'Add filter');
    await c.d.tap(text: 'Genres');
    await c.d.type('Baroque', submit: true);
    await c.d.unfocus();
  }, cleanup: (c) => c.d.tap(text: 'Clear')),
  Scene('edit_score', (c) async {
    await c.d.go('/scores/${c.library.score(_bach)}/edit');
  }),
  Scene('annotate', (c) async {
    await c.d.go('/scores/${c.library.score(_bach)}/edit/annotate');
    if (c.desktop) {
      // Zoomed out to the whole page width, like on a desktop monitor.
      await c.d.call('key', {'modifiers': ['control'], 'hold': 'down'});
      for (var i = 0; i < 3; i++) {
        await c.d.call('scroll', {'x': c.size[0] / 2, 'y': c.size[1] / 2, 'dy': 105, 'kind': 'mouse'});
      }
      await c.d.call('key', {'modifiers': ['control'], 'hold': 'up'});
    }
  }),
  Scene('play_setlist', (c) async {
    await c.d.go('/setlists/${c.library.setlist('Spring Recital')}/play');
    // The page viewer swallows a single touch tap on desktop, a mouse click
    // opens the sheet.
    for (final kind in ['mouse', 'touch', 'mouse']) {
      await c.d.tap(text: 'Spring Recital', kind: kind);
      if (await c.d.visible(text: 'Minuet in G, BWV Anh. 114')) return;
    }
    throw ToolException('the setlist sheet did not open');
  }),
  Scene('practice_tab', (c) async {
    final items = await c.d.findAll(text: 'Practice');
    // Score tags are called Practice too, the navigation item lines up with
    // Setlists in the bar or rail.
    final setlists = (await c.d.find(text: 'Setlists')).center;
    final nav = items
        .where((i) => (i.center[0] - setlists[0]).abs() < 2 || (i.center[1] - setlists[1]).abs() < 2)
        .firstOrNull;
    if (nav == null) throw ToolException('no Practice navigation item');
    await c.d.tapAt(nav.center);
    await c.d.settle();
  }),
  Scene('practice_routine', (c) async {
    await c.d.go(_dailyPiano(c));
  }),
  Scene('practice_play', (c) async {
    await c.d.go('${_dailyPiano(c)}/play');
    // The routine resumes at the exercise in progress, the README shows the
    // first one not started yet.
    for (var i = 0; i < 4; i++) {
      final next = await c.d.findAll(text: 'Next');
      // The start overlay is above the bottom bar, so it comes last.
      await c.d.tapAt(next.last.center);
      await c.d.settle();
    }
    await c.d.find(text: 'Exercise 5 of 7');
  }),
  Scene('exercise_edit', (c) async {
    await c.d.go('/practice/exercises/${c.library.exercise('Scales')}');
    // Below the TwoPanePage breakpoint the panes are tabs.
    if (await c.d.visible(text: 'Scores (', contains: true)) await c.d.tap(text: 'Scores (', contains: true);
  }),
  Scene('practice_statistics', (c) async {
    await c.d.go('/practice/statistics');
    // The current week may have only today, the previous one is complete.
    await c.d.tap(tooltip: 'Previous');
  }),
];

String _dailyPiano(SceneContext c) => '/practice/routines/${c.library.routine('Daily piano')}/details';

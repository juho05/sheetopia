import 'dart:typed_data';

import 'driver.dart';
import 'stage.dart';

/// One set of screenshots, e.g. the README images or the screenshots for one
/// store slot. Add a store by adding a form factor to a target.
class FormFactor {
  final String id;
  final String description;

  /// Exact pixel size of every screenshot, checked after capturing.
  final int width;
  final int height;

  /// README screenshots keep the window decoration's transparency and carry
  /// the app version in their file name. Store screenshots must be opaque.
  final bool readme;

  const FormFactor(this.id, this.description, this.width, this.height, {this.readme = false});
}

abstract class Target {
  String get id;

  List<FormFactor> get formFactors;

  /// Why this host can't capture this target, null if it can.
  Future<String?> unavailableReason();

  Future<void> build(Stage stage, String logDir);

  /// Starts the app with fresh data and connects to it.
  Future<AppDriver> start(Stage stage, FormFactor formFactor, String logDir);

  Future<Uint8List> capture(AppDriver driver, FormFactor formFactor);

  /// Called after the last scene of a form factor.
  Future<void> finish(FormFactor formFactor) async {}

  /// Tears everything down, also after failures.
  Future<void> close();
}

const flutterDefines = ['--dart-define=VERSION_CHECK=false'];

final vmServicePattern = RegExp(r'Dart VM [Ss]ervice.*?(http://127\.0\.0\.1:\d+/\S*/)');

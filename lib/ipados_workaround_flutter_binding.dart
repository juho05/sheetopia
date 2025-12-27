import 'package:flutter/material.dart';

// https://github.com/flutter/flutter/issues/175606#issuecomment-3577593591
class IPadOSWorkaroundFlutterBinding extends WidgetsFlutterBinding {
  // Track timestamp of last real (non-zero) pointer up event
  DateTime? _lastRealPointerUpTime;
  static const int _fakeTapThreshold = 400;

  @override
  void handlePointerEvent(PointerEvent event) {
    // Track when real taps (non-zero position) complete
    if (event is PointerUpEvent && event.position != Offset.zero) {
      _lastRealPointerUpTime = DateTime.now();
    }

    // Filter fake taps: Offset.zero down events that follow shortly after a real tap
    if (event.position == Offset.zero && event is PointerDownEvent) {
      if (_lastRealPointerUpTime != null) {
        final timeSinceRealTap = DateTime.now()
            .difference(_lastRealPointerUpTime!)
            .inMilliseconds;
        if (timeSinceRealTap < _fakeTapThreshold) {
          return;
        }
      }
    }

    // Also block the matching PointerUpEvent for a blocked PointerDownEvent
    if (event.position == Offset.zero && event is PointerUpEvent) {
      if (_lastRealPointerUpTime != null) {
        final timeSinceRealTap = DateTime.now()
            .difference(_lastRealPointerUpTime!)
            .inMilliseconds;
        if (timeSinceRealTap < _fakeTapThreshold) {
          return;
        }
      }
    }

    super.handlePointerEvent(event);
  }
}

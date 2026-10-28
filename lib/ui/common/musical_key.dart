/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/data/repositories/scores/musical_key.dart';
import 'package:sheetopia/ui/common/metadata_row.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/common/surface.dart';

class MusicalKeySelector extends StatefulWidget {
  final MusicalKey? value;
  final void Function(MusicalKey? key) onChanged;

  const MusicalKeySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<MusicalKeySelector> createState() => _MusicalKeySelectorState();
}

class _MusicalKeySelectorState extends State<MusicalKeySelector> {
  late bool _minor = widget.value?.minor ?? false;

  @override
  void didUpdateWidget(covariant MusicalKeySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) _minor = widget.value?.minor ?? false;
  }

  void _setTonic(String tonic) {
    widget.onChanged(tonic.isEmpty ? null : MusicalKey(tonic, minor: _minor));
  }

  void _setMinor(bool minor) {
    setState(() => _minor = minor);
    final value = widget.value;
    if (value != null) widget.onChanged(MusicalKey(value.tonic, minor: minor));
  }

  @override
  Widget build(BuildContext context) {
    final tonic = widget.value?.tonic;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MenuBox<String>(
          tooltip: "Tonic",
          value: tonic ?? "",
          label: tonic == null ? "\u2014" : MusicalKey.displayTonic(tonic),
          muted: tonic == null,
          sizeTo: MusicalKey.tonics.map(MusicalKey.displayTonic),
          options: {
            "": "Not set",
            for (final t in MusicalKey.tonics) t: MusicalKey.displayTonic(t),
          },
          onSelected: _setTonic,
        ),
        _MenuBox<bool>(
          tooltip: "Mode",
          value: _minor,
          label: _minor ? "Minor" : "Major",
          muted: tonic == null,
          sizeTo: const ["Major", "Minor"],
          options: const {false: "Major", true: "Minor"},
          onSelected: _setMinor,
        ),
      ],
    );
  }
}

class _MenuBox<T> extends StatelessWidget {
  final String tooltip;
  final T value;
  final String label;
  final bool muted;

  final Iterable<String> sizeTo;
  final Map<T, String> options;
  final void Function(T value) onSelected;

  const _MenuBox({
    required this.tooltip,
    required this.value,
    required this.label,
    required this.muted,
    required this.sizeTo,
    required this.options,
    required this.onSelected,
  });

  Widget _text(String text, TextStyle style) => Text(
    text,
    maxLines: 1,
    style: style,
    // the bundled accidentals have taller line metrics than Roboto
    strutStyle: StrutStyle.fromTextStyle(style, forceStrutHeight: true),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    final style = theme.textTheme.bodyLarge!.copyWith(
      color: muted ? mutedColor : null,
    );
    return Material(
      color: Surface.badgeOf(context),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: PopupMenuButton<T>(
        tooltip: tooltip,
        initialValue: value,
        onSelected: onSelected,
        itemBuilder: (context) => [
          for (final MapEntry(:key, :value) in options.entries)
            PopupMenuItem(value: key, child: Text(value)),
        ],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IntrinsicWidth(
              child: InputDecorator(
                decoration: metadataInputDecoration(context, filled: false),
                child: Stack(
                  children: [
                    for (final text in sizeTo)
                      Visibility.maintain(
                        visible: false,
                        child: _text(text, style),
                      ),
                    _text(label, style),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Symbols.arrow_drop_down, color: mutedColor),
            ),
          ],
        ),
      ),
    );
  }
}

class MusicalKeyDialog extends StatefulWidget {
  final String title;
  final String submitBtnText;

  const MusicalKeyDialog._({required this.title, required this.submitBtnText});

  static Future<MusicalKey?> show(
    BuildContext context, {
    required String title,
    required String submitBtnText,
  }) {
    return showSheetopiaDialog<MusicalKey>(
      context: context,
      builder: (context) =>
          MusicalKeyDialog._(title: title, submitBtnText: submitBtnText),
    );
  }

  @override
  State<MusicalKeyDialog> createState() => _MusicalKeyDialogState();
}

class _MusicalKeyDialogState extends State<MusicalKeyDialog> {
  MusicalKey? _value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SheetopiaDialog(
      maxWidth: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          Text(
            widget.title,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall,
          ),
          MusicalKeySelector(
            value: _value,
            onChanged: (value) => setState(() => _value = value),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              FilledButton(
                onPressed: _value == null
                    ? null
                    : () => Navigator.pop(context, _value),
                child: Text(widget.submitBtnText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

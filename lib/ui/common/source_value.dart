/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/ui/common/toast.dart';
import 'package:sheetopia/ui/edit_score/source_link_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class SourceState {
  String? _name;
  String? _link;

  String? get name => _name;

  /// kept while the name is empty so retyping the name restores it
  String? get link => _link;

  String get savedLink => _name != null ? _link ?? "" : "";

  void load(String? name, String? link) {
    _name = name;
    _link = link;
  }

  /// keeps a remembered link if the name was already empty
  void sync(String? name, String? link) {
    if (name == null && _name == null) return;
    load(name, link);
  }

  void set(String name, String link) {
    _name = name.isNotEmpty ? name : null;
    _link = _name != null && link.isNotEmpty ? link : null;
  }

  /// returns true when the new name differs from the old name
  bool updateName(String name) {
    if (name == (_name ?? "")) return false;
    _name = name.isNotEmpty ? name : null;
    return true;
  }

  void clear() => load(null, null);
}

class SourceValue extends StatelessWidget {
  /// the controller of [field]
  final TextEditingController controller;
  final Widget field;
  final String? link;
  final void Function(String link) onLinkChanged;

  const SourceValue({
    super.key,
    required this.controller,
    required this.field,
    required this.link,
    required this.onLinkChanged,
  });

  Future<void> _open(String link) async {
    try {
      final opened = await launchUrl(
        Uri.parse(link),
        mode: LaunchMode.externalApplication,
      );
      if (opened) return;
      Log.warn("no app to open source link $link");
    } catch (e, st) {
      Log.error("failed to open source link", e: e, st: st);
    }
    Toast.show("Could not open the link!");
  }

  Future<void> _edit(BuildContext context) async {
    final result = await SourceLinkDialog.show(context, link: link ?? "");
    if (result != null) onLinkChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final link = this.link;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: field),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final hasSource = controller.text.trim().isNotEmpty;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (link != null && hasSource)
                  IconButton(
                    icon: const Icon(Symbols.open_in_new),
                    iconSize: 20,
                    tooltip: link,
                    onPressed: () => _open(link),
                  ),
                IconButton(
                  icon: Icon(link == null ? Symbols.add_link : Symbols.link),
                  iconSize: 20,
                  tooltip: link == null ? "Add link" : "Edit link",
                  onPressed: hasSource ? () => _edit(context) : null,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

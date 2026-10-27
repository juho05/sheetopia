/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
import 'package:dotted_border/dotted_border.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reactive_forms/reactive_forms.dart' hide ReactiveTextField;
import 'package:sheetopia/ui/common/auto_complete_field.dart';
import 'package:sheetopia/ui/common/metadata_field.dart';
import 'package:sheetopia/ui/common/reactive_text_field.dart';
import 'package:sheetopia/ui/common/surface.dart';

InputDecoration metadataInputDecoration(
  BuildContext context, {
  String? hintText,
  Widget? suffixIcon,
  bool filled = true,
}) {
  const radius = BorderRadius.all(Radius.circular(8));
  return InputDecoration(
    hintText: hintText,
    isDense: true,
    filled: filled,
    fillColor: Surface.badgeOf(context),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: const OutlineInputBorder(borderRadius: radius),
    enabledBorder: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide.none,
    ),
    suffixIcon: suffixIcon,
  );
}

class MetadataAutoCompleteField extends StatelessWidget {
  final FormGroup form;
  final String formControlName;
  final TextEditingController? controller;
  final FocusNode focusNode;
  final Future<Iterable<String>> Function(String filter) getOptions;

  const MetadataAutoCompleteField({
    super.key,
    required this.form,
    required this.formControlName,
    this.controller,
    required this.focusNode,
    required this.getOptions,
  });

  @override
  Widget build(BuildContext context) {
    return AutoCompleteField(
      controller: controller,
      focusNode: focusNode,
      getOptions: getOptions,
      onSelected: (option) => form.control(formControlName).value = option,
      fieldBuilder: (context, controller, focusNode) => ReactiveTextField(
        onTapOutside: (event) => focusNode.unfocus(),
        formControlName: formControlName,
        controller: controller,
        focusNode: focusNode,
        decoration: metadataInputDecoration(context, hintText: "Not set"),
      ),
    );
  }
}

class MetadataCard extends StatelessWidget {
  final Widget? title;
  final List<Widget> children;

  const MetadataCard({super.key, this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    return Material(
      color: Surface.raisedOf(context),
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Surface.tile(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ...[title, const SizedBox(height: 7)],
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class MetadataRow extends StatelessWidget {
  static const double _labelWidth = 128;
  static const double _minHeight = 48;
  static const double _stackBelow = 400;

  final IconData icon;
  final String label;
  final Widget child;
  final List<Widget> trailing;
  final bool stacked;
  final void Function()? onRemove;

  const MetadataRow({
    super.key,
    required this.icon,
    required this.label,
    required this.child,
    this.trailing = const [],
    this.stacked = false,
    this.onRemove,
  });

  MetadataRow.field(
    MetadataField field, {
    Key? key,
    required this.child,
    this.trailing = const [],
    this.stacked = false,
    this.onRemove,
  }) : icon = field.icon,
       label = field.label,
       super(key: key ?? ValueKey(field));

  Widget _label(ThemeData theme, {bool expand = true}) {
    final color = theme.colorScheme.onSurfaceVariant;
    final text = Text(
      label,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodyMedium!.copyWith(color: color),
    );
    return Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      spacing: 12,
      children: [
        Icon(icon, size: 20, color: color),
        if (expand) Expanded(child: text) else Flexible(child: text),
      ],
    );
  }

  List<Widget> _trailing() {
    final onRemove = this.onRemove;
    return [
      ...trailing,
      if (onRemove != null)
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          iconSize: 18,
          visualDensity: VisualDensity.compact,
          tooltip: "Remove field",
          onPressed: onRemove,
        ),
    ];
  }

  Widget _wide(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: _labelWidth, height: _minHeight, child: _label(theme)),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _minHeight),
            child: Align(alignment: Alignment.centerLeft, child: child),
          ),
        ),
        ..._trailing().map(
          (w) => SizedBox(
            height: _minHeight,
            child: Center(child: w),
          ),
        ),
      ],
    );
  }

  Widget _narrow(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 40,
          child: Row(
            children: [
              Expanded(child: _label(theme, expand: false)),
              ..._trailing(),
            ],
          ),
        ),
        Padding(padding: const EdgeInsets.only(bottom: 8), child: child),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (stacked) return _narrow(theme);
    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth < _stackBelow ? _narrow(theme) : _wide(theme),
    );
  }
}

class MetadataChips extends StatelessWidget {
  final Iterable<Widget> chips;
  final void Function()? onAdd;
  final String addTooltip;

  const MetadataChips({
    super.key,
    required this.chips,
    this.onAdd,
    this.addTooltip = "Add",
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const radius = Radius.circular(14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ...chips,
          if (onAdd != null)
            Tooltip(
              message: addTooltip,
              child: DottedBorder(
                options: RoundedRectDottedBorderOptions(
                  radius: radius,
                  padding: EdgeInsets.zero,
                  strokeWidth: 2,
                  dashPattern: const [8, 4],
                  color: Color.lerp(
                    Surface.badgeOf(context),
                    theme.colorScheme.onSurface,
                    0.15,
                  )!,
                ),
                child: InkWell(
                  onTap: onAdd,
                  borderRadius: const BorderRadius.all(radius),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        const Icon(Icons.add, size: 14),
                        Text("Add", style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

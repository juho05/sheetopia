/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:math' as math;

import 'package:flutter/material.dart';

class FabMenuItem {
  final IconData? icon;
  final String label;
  final void Function()? onPressed;

  const FabMenuItem({this.icon, required this.label, required this.onPressed});
}

class FabMenu extends StatefulWidget {
  final List<FabMenuItem> items;
  final Widget? icon;
  final Widget closeIcon;
  final Widget? label;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool _extended;

  const FabMenu({
    super.key,
    required this.items,
    this.icon,
    this.closeIcon = const Icon(Icons.close),
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  }) : label = null,
       _extended = false;

  const FabMenu.extended({
    super.key,
    required this.items,
    this.label,
    this.icon,
    this.closeIcon = const Icon(Icons.close),
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  }) : _extended = true;

  @override
  State<FabMenu> createState() => _FabMenuState();
}

class _FabMenuState extends State<FabMenu> with SingleTickerProviderStateMixin {
  static const _itemHeight = 56.0;
  static const _itemSpacing = 12.0;
  static const _menuSpacing = 16.0;
  static const _slideDistance = 48.0;
  static const _stagger = 0.2;

  final _portalController = OverlayPortalController();
  final _layerLink = LayerLink();
  final _triggerKey = GlobalKey();

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
    reverseDuration: const Duration(milliseconds: 200),
  );

  bool get _open =>
      _controller.status == AnimationStatus.forward ||
      _controller.status == AnimationStatus.completed;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_onStatusChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      _portalController.hide();
    }
    setState(() {});
  }

  void _show() {
    _portalController.show();
    _controller.forward();
  }

  void _hide() {
    _controller.reverse();
  }

  void _select(FabMenuItem item) {
    _hide();
    item.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.length < 2) return _buildSingle();

    return PopScope(
      canPop: !_open,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _hide();
      },
      child: OverlayPortal(
        controller: _portalController,
        overlayChildBuilder: _buildMenu,
        child: CompositedTransformTarget(
          link: _layerLink,
          child: KeyedSubtree(key: _triggerKey, child: _buildTrigger()),
        ),
      ),
    );
  }

  Widget _icon([FabMenuItem? item]) {
    if (widget.icon != null) return widget.icon!;
    if (item?.icon != null) return Icon(item!.icon);
    return const Icon(Icons.add);
  }

  Widget _buildSingle() {
    final item = widget.items.isEmpty ? null : widget.items.first;
    if (widget._extended) {
      return FloatingActionButton.extended(
        onPressed: item?.onPressed,
        tooltip: widget.tooltip,
        backgroundColor: widget.backgroundColor,
        foregroundColor: widget.foregroundColor,
        icon: _icon(item),
        label:
            widget.label ??
            (item != null ? Text(item.label) : const SizedBox.shrink()),
      );
    }
    return FloatingActionButton(
      onPressed: item?.onPressed,
      tooltip: widget.tooltip ?? item?.label,
      backgroundColor: widget.backgroundColor,
      foregroundColor: widget.foregroundColor,
      child: _icon(item),
    );
  }

  Widget _buildTrigger() {
    void toggle() => _open ? _hide() : _show();
    if (!widget._extended) {
      return FloatingActionButton(
        onPressed: toggle,
        tooltip: _open ? null : widget.tooltip,
        backgroundColor: widget.backgroundColor,
        foregroundColor: widget.foregroundColor,
        child: _buildAnimatedIcon(),
      );
    }
    final collapse = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    return AnimatedBuilder(
      animation: collapse,
      builder: (context, _) {
        final value = collapse.value;
        return FloatingActionButton.extended(
          onPressed: toggle,
          tooltip: _open ? null : widget.tooltip,
          backgroundColor: widget.backgroundColor,
          foregroundColor: widget.foregroundColor,
          // collapses to the 56x56 of a regular fab: 16 + 24 (icon) + 16
          extendedIconLabelSpacing: 8 * (1 - value),
          extendedPadding: EdgeInsetsDirectional.only(
            start: 16,
            end: 20 - 4 * value,
          ),
          icon: _buildAnimatedIcon(),
          label: ClipRect(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 1 - value,
              child: Opacity(
                opacity: (1 - value * 2).clamp(0.0, 1.0),
                child: widget.label ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedIcon() {
    final rotation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    return AnimatedBuilder(
      animation: rotation,
      builder: (context, _) {
        final value = rotation.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 1 - value,
              child: Transform.rotate(
                angle: value * math.pi / 4,
                child: _icon(),
              ),
            ),
            Opacity(
              opacity: value,
              child: Transform.rotate(
                angle: (value - 1) * math.pi / 4,
                child: widget.closeIcon,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenu(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final maxWidth = MediaQuery.sizeOf(context).width - 32;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Stack(
        children: [..._buildBarrier(context), _buildItems(rtl, maxWidth)],
      ),
    );
  }

  // leaves a hole over the trigger so it keeps handling its own taps
  List<Widget> _buildBarrier(BuildContext context) {
    final trigger = _triggerRect(context);
    if (trigger == null) {
      return [Positioned.fill(child: _barrier())];
    }
    return [
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        height: trigger.top,
        child: _barrier(),
      ),
      Positioned(
        left: 0,
        right: 0,
        top: trigger.bottom,
        bottom: 0,
        child: _barrier(),
      ),
      Positioned(
        left: 0,
        width: trigger.left,
        top: trigger.top,
        height: trigger.height,
        child: _barrier(),
      ),
      Positioned(
        left: trigger.right,
        right: 0,
        top: trigger.top,
        height: trigger.height,
        child: _barrier(),
      ),
    ];
  }

  Widget _barrier() =>
      GestureDetector(behavior: HitTestBehavior.opaque, onTap: _hide);

  Rect? _triggerRect(BuildContext context) {
    final trigger =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (trigger == null ||
        !trigger.hasSize ||
        overlay == null ||
        !overlay.hasSize) {
      return null;
    }
    return trigger.localToGlobal(Offset.zero, ancestor: overlay) & trigger.size;
  }

  Widget _buildItems(bool rtl, double maxWidth) {
    return Positioned(
      left: 0,
      top: 0,
      child: CompositedTransformFollower(
        link: _layerLink,
        targetAnchor: rtl ? Alignment.topLeft : Alignment.topRight,
        followerAnchor: rtl ? Alignment.bottomLeft : Alignment.bottomRight,
        offset: const Offset(0, -_menuSpacing),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: rtl
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < widget.items.length; i++) ...[
                if (i > 0) const SizedBox(height: _itemSpacing),
                _buildItem(i, rtl),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(int index, bool rtl) {
    final count = widget.items.length;
    // the item closest to the fab animates first
    final start = (count - 1 - index) * (_stagger / (count - 1));
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, start + 1 - _stagger, curve: Curves.easeOutCubic),
      reverseCurve: Interval(
        start,
        start + 1 - _stagger,
        curve: Curves.easeInCubic,
      ),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = animation.value;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(
              (1 - value) * (rtl ? -_slideDistance : _slideDistance),
              0,
            ),
            child: child,
          ),
        );
      },
      child: _FabMenuEntry(
        item: widget.items[index],
        onPressed: () => _select(widget.items[index]),
      ),
    );
  }
}

class _FabMenuEntry extends StatelessWidget {
  final FabMenuItem item;
  final void Function() onPressed;

  const _FabMenuEntry({required this.item, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final enabled = item.onPressed != null;
    final foreground = enabled
        ? colors.onPrimaryContainer
        : colors.onSurface.withValues(alpha: 0.38);
    return Material(
      color: enabled
          ? colors.primaryContainer
          : colors.onSurface.withValues(alpha: 0.12),
      elevation: enabled ? 3 : 0,
      shadowColor: theme.shadowColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        child: SizedBox(
          height: _FabMenuState._itemHeight,
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: item.icon != null ? 16 : 20,
              end: 20,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.icon != null) ...[
                  Icon(item.icon, color: foreground),
                  const SizedBox(width: 12),
                ],
                Flexible(
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

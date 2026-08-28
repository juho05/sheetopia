/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';

/// Scaffold that shows two panes side by side on wide screens and as tabs on
/// narrow ones. The pane builders are only called while [loading] is false.
class TwoPanePage extends StatelessWidget {
  static const double breakpoint = 900;

  final PreferredSizeWidget? appBar;
  final String primaryLabel;
  final String secondaryLabel;
  final WidgetBuilder primary;
  final WidgetBuilder secondary;
  final bool loading;

  /// Disables swiping between the tabs while the secondary tab is selected.
  final bool lockSecondarySwipe;

  const TwoPanePage({
    super.key,
    this.appBar,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.primary,
    required this.secondary,
    this.loading = false,
    this.lockSecondarySwipe = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < breakpoint) {
              return _TwoPaneTabs(
                primaryLabel: primaryLabel,
                secondaryLabel: secondaryLabel,
                primary: primary,
                secondary: secondary,
                loading: loading,
                lockSecondarySwipe: lockSecondarySwipe,
              );
            }
            if (loading) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }
            return Row(
              children: [
                Expanded(child: primary(context)),
                const VerticalDivider(),
                Expanded(child: secondary(context)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TwoPaneTabs extends StatefulWidget {
  final String primaryLabel;
  final String secondaryLabel;
  final WidgetBuilder primary;
  final WidgetBuilder secondary;
  final bool loading;
  final bool lockSecondarySwipe;

  const _TwoPaneTabs({
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.primary,
    required this.secondary,
    required this.loading,
    required this.lockSecondarySwipe,
  });

  @override
  State<_TwoPaneTabs> createState() => _TwoPaneTabsState();
}

class _TwoPaneTabsState extends State<_TwoPaneTabs>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar.secondary(
          controller: _tabController,
          tabs: [
            Tab(text: widget.primaryLabel),
            Tab(text: widget.secondaryLabel),
          ],
        ),
        Expanded(
          child: widget.loading
              ? const Center(child: CircularProgressIndicator.adaptive())
              : ListenableBuilder(
                  listenable: _tabController,
                  builder: (context, _) => TabBarView(
                    controller: _tabController,
                    physics:
                        widget.lockSecondarySwipe && _tabController.index == 1
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: widget.primary(context),
                      ),
                      widget.secondary(context),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

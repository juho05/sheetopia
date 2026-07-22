/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/setlists/setlists_repository.dart';
import 'package:sheetopia/ui/score/score_page.dart';
import 'package:sheetopia/ui/setlists/setlist_navigation_viewmodel.dart';

class SetlistPlayPage extends StatefulWidget {
  final String setlistId;

  const SetlistPlayPage({super.key, required this.setlistId});

  @override
  State<SetlistPlayPage> createState() => _SetlistPlayPageState();
}

class _SetlistPlayPageState extends State<SetlistPlayPage> {
  SetlistNavigationViewModel? _navigation;

  @override
  void initState() {
    super.initState();
    final setlistsRepo = context.read<SetlistsRepository>();
    final scoresRepo = context.read<ScoresRepository>();
    setlistsRepo.getSetlist(widget.setlistId).then((setlist) {
      if (!mounted || setlist == null) return;
      setState(
        () => _navigation = SetlistNavigationViewModel(
          setlist,
          repo: setlistsRepo,
          scoresRepo: scoresRepo,
        )..addListener(_onNavigationChanged),
      );
    });
  }

  @override
  void dispose() {
    _navigation?.removeListener(_onNavigationChanged);
    _navigation?.dispose();
    super.dispose();
  }

  void _onNavigationChanged() {
    if (!mounted) return;
    if (_navigation!.deleted) {
      context.go("/");
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final navigation = _navigation;
    if (navigation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    final scoreId = navigation.currentScoreId;
    if (scoreId == null) {
      final theme = Theme.of(context);
      return Scaffold(
        appBar: AppBar(title: Text(navigation.name)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 16,
              children: [
                Text(
                  navigation.length == 0
                      ? "This setlist is empty."
                      : "None of these scores are downloaded yet.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text("Back"),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return ScorePage(scoreId: scoreId, setlistNavigation: navigation);
  }
}

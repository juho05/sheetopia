/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/ui/edit_score/edit_score_form.dart';
import 'package:sheetopia/ui/edit_score/edit_score_preview.dart';
import 'package:sheetopia/ui/edit_score/edit_score_viewmodel.dart';

class EditScoreMobile extends StatefulWidget {
  const EditScoreMobile({super.key});

  @override
  State<EditScoreMobile> createState() => _EditScoreMobileState();
}

class _EditScoreMobileState extends State<EditScoreMobile>
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
            const Tab(text: "Metadata"),
            const Tab(text: "File"),
          ],
        ),
        Expanded(
          child: Consumer<EditScoreViewModel>(
            builder: (context, viewModel, _) {
              if (viewModel.score == null) {
                return const Center(
                  child: CircularProgressIndicator.adaptive(),
                );
              }
              return ListenableBuilder(
                listenable: _tabController,
                builder: (context, _) {
                  return TabBarView(
                    controller: _tabController,
                    physics: _tabController.index == 1
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: EditScoreForm(),
                      ),
                      EditScorePreview(score: viewModel.score!),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

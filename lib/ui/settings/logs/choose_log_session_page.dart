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
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/ui/settings/logs/choose_log_session_page_viewmodel.dart';
import 'package:sheetopia/utils/format.dart';

class ChooseLogSessionPage extends StatelessWidget {
  final DateTime? highlight;
  const ChooseLogSessionPage({super.key, this.highlight});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    return ChangeNotifierProvider(
      create: (context) =>
          ChooseLogSessionPageViewModel(logRepository: context.read()),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text("Choose Session")),
          body: SafeArea(
            child: Consumer<ChooseLogSessionPageViewModel>(
              builder: (context, viewModel, _) {
                return ListView.builder(
                  itemBuilder: (BuildContext context, int index) {
                    final s = viewModel
                        .sessions[viewModel.sessions.length - 1 - index];
                    final title =
                        formatDateTime(s) +
                        (s == Log.sessionStartTime ? " (Current)" : "");
                    return ListTile(
                      title: Text(
                        title,
                        style: textStyle.copyWith(
                          fontWeight: s == highlight ? FontWeight.bold : null,
                        ),
                      ),
                      onTap: () {
                        context.pop(s);
                      },
                      trailing: s == highlight
                          ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.check),
                            )
                          : null,
                    );
                  },
                  itemCount: viewModel.sessions.length,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

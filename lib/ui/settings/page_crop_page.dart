/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/settings/page_crop.dart';
import 'package:sheetopia/data/repositories/settings/settings_repository.dart';
import 'package:sheetopia/ui/settings/page_crop_viewmodel.dart';

class PageCropPage extends StatelessWidget {
  const PageCropPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PageCropViewModel(
        settings: context.read<SettingsRepository>().pageCrop,
      ),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text("Page Margins")),
          body: SafeArea(
            child: Consumer<PageCropViewModel>(
              builder: (context, viewModel, _) {
                final padding = viewModel.paddingPercent;
                return ListView(
                  children: [
                    SwitchListTile(
                      title: const Text("Crop page margins"),
                      subtitle: const Text(
                        "Hide the empty margins of a score in the score viewer",
                      ),
                      value: viewModel.enabled,
                      onChanged: viewModel.updateEnabled,
                    ),
                    ListTile(
                      enabled: viewModel.enabled,
                      title: const Text("Padding"),
                      subtitle: const Text(
                        "Empty space kept around the content",
                      ),
                      trailing: Text("$padding %"),
                    ),
                    Slider(
                      value: padding,
                      max: PageCropSettings.maxPaddingPercent,
                      divisions:
                          PageCropSettings.maxPaddingPercent ~/
                          PageCropSettings.paddingPercentStep,
                      label: "$padding %",
                      onChanged: viewModel.enabled
                          ? viewModel.dragPaddingPercent
                          : null,
                      onChangeEnd: viewModel.enabled
                          ? viewModel.updatePaddingPercent
                          : null,
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

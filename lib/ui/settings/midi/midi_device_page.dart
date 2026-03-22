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
import 'package:sheetopia/ui/settings/midi/midi_device_viewmodel.dart';

class MidiDevicePage extends StatelessWidget {
  final String deviceId;
  const MidiDevicePage({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MidiDeviceViewModel>(
      create: (context) => MidiDeviceViewModel(
        midiRepository: context.read(),
        deviceId: deviceId,
      ),
      builder: (context, _) {
        return Consumer<MidiDeviceViewModel>(
          builder: (context, viewModel, _) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  viewModel.device?.name ?? "",
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              body: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(8.0),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SetMidiAction(
                        title: "Next page",
                        recording: viewModel.recordingNextPage,
                        disabled: viewModel.recordingPrevPage,
                        value: viewModel.nextPageMapping,
                        onSet: viewModel.recordNextPage,
                        onCancel: viewModel.cancelNextPage,
                        onReset: viewModel.resetNextPage,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SetMidiAction(
                        title: "Prev page",
                        recording: viewModel.recordingPrevPage,
                        disabled: viewModel.recordingNextPage,
                        value: viewModel.prevPageMapping,
                        onSet: viewModel.recordPrevPage,
                        onCancel: viewModel.cancelPrevPage,
                        onReset: viewModel.resetPrevPage,
                      ),
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () async {
                            await viewModel.disconnect();
                            if (!context.mounted) return;
                            context.pop();
                          },
                          child: const Text("Disconnect"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SetMidiAction extends StatelessWidget {
  final String title;
  final String? value;
  final bool recording;
  final void Function() onSet;
  final void Function() onCancel;
  final void Function() onReset;
  final bool disabled;

  const _SetMidiAction({
    required this.title,
    required this.recording,
    this.value,
    required this.onSet,
    required this.onCancel,
    required this.onReset,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        Text("$title:"),
        if (recording)
          OutlinedButton(onPressed: onCancel, child: const Text("Cancel"))
        else if (value == null)
          FilledButton.icon(
            onPressed: !disabled ? onSet : null,
            label: const Text("Set"),
            icon: const Icon(Icons.edit),
          )
        else
          Row(
            spacing: 8,
            children: [
              Text(value!),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onReset,
              ),
            ],
          ),
      ],
    );
  }
}

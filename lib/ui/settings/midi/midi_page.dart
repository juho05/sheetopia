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
import 'package:sheetopia/ui/common/heading.dart';
import 'package:sheetopia/ui/settings/midi/midi_viewmodel.dart';

class MidiPage extends StatelessWidget {
  const MidiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MidiViewModel>(
      create: (context) => MidiViewModel(midiRepository: context.read()),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text("MIDI Devices")),
          body: SafeArea(
            child: Consumer<MidiViewModel>(
              builder: (context, viewModel, _) {
                final connectedDevices = viewModel.devices.where(
                  (device) => device.connected,
                );
                final disconnectedDevices = viewModel.devices.where(
                  (device) => !device.connected,
                );
                return CustomScrollView(
                  slivers: [
                    if (connectedDevices.isNotEmpty)
                      const SliverHeading(
                        text: "Connected",
                        padding: EdgeInsets.all(8),
                      ),
                    SliverList.list(
                      children: connectedDevices
                          .map(
                            (device) => ListTile(
                              leading: Icon(_deviceIcon(device.type)),
                              title: Text(device.name),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                context.go(
                                  "/settings/midi/devices/${Uri.encodeComponent(device.id)}",
                                );
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SliverPadding(
                      padding: EdgeInsets.all(8),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          spacing: 8,
                          children: [
                            Heading(text: "Discovered"),
                            SizedBox.square(
                              dimension: 10,
                              child: CircularProgressIndicator.adaptive(
                                strokeWidth: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverList.list(
                      children: disconnectedDevices
                          .map(
                            (device) => ListTile(
                              leading: Icon(_deviceIcon(device.type)),
                              title: Text(device.name),
                              trailing: FilledButton(
                                onPressed:
                                    !viewModel.connectingIds.contains(device.id)
                                    ? () {
                                        viewModel.connectDevice(device);
                                      }
                                    : null,
                                child: Text(
                                  viewModel.connectingIds.contains(device.id)
                                      ? "Connecting…"
                                      : "Connect",
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    if (viewModel.rememberedAbsent.isNotEmpty)
                      const SliverHeading(
                        text: "Remembered",
                        padding: EdgeInsets.all(8),
                      ),
                    SliverList.list(
                      children: viewModel.rememberedAbsent
                          .map(
                            (key) => ListTile(
                              leading: Icon(_deviceIcon(key.type)),
                              title: Text(key.name),
                              subtitle: const Text("Reconnects automatically"),
                              trailing: TextButton(
                                onPressed: () => viewModel.forget(key),
                                child: const Text("Forget"),
                              ),
                            ),
                          )
                          .toList(),
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

IconData _deviceIcon(String type) => switch (type) {
  "native" => Icons.devices,
  "network" => Icons.wifi,
  "BLE" || "bonded" || "bluetooth" => Icons.bluetooth,
  _ => Icons.device_unknown,
};

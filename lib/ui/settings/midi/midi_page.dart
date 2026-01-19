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
                              leading: Icon(switch (device.type) {
                                "native" => Icons.devices,
                                "network" => Icons.wifi,
                                "BLE" || "bonded" => Icons.bluetooth,
                                _ => Icons.device_unknown,
                              }),
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
                              leading: Icon(switch (device.type) {
                                "native" => Icons.devices,
                                "network" => Icons.wifi,
                                "BLE" || "bonded" => Icons.bluetooth,
                                _ => Icons.device_unknown,
                              }),
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

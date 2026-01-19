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
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
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

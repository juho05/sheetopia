import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              title: const Text("MIDI Devices"),
              trailing: const Icon(Icons.arrow_forward_ios_outlined),
              onTap: () {
                context.go("/settings/midi");
              },
            ),
            ListTile(
              title: const Text("Debug"),
              trailing: const Icon(Icons.arrow_forward_ios_outlined),
              onTap: () {
                context.go("/settings/debug");
              },
            ),
          ],
        ),
      ),
    );
  }
}

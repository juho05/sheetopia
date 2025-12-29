import 'package:flutter/material.dart';

class SyncPage extends StatelessWidget {
  const SyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sync settings")),
      body: const SafeArea(child: Placeholder()),
    );
  }
}

/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/logger/log_message.dart';
import 'package:sheetopia/ui/common/toast.dart';
import 'package:sheetopia/ui/settings/logs/log_colors.dart';
import 'package:sheetopia/utils/format.dart';

class LogDetailsPage extends StatelessWidget {
  final LogMessage msg;

  const LogDetailsPage({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    return Scaffold(
      appBar: AppBar(title: const Text("Message Details")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Text(
                msg.level.name.toUpperCase(),
                style: textStyle.copyWith(
                  color: levelColors[msg.level],
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              LogMessageDetailsField(
                label: "Time",
                content: formatDateTime(msg.time),
              ),
              LogMessageDetailsField(label: "Tag", content: msg.tag),
              LogMessageDetailsField(label: "Message", content: msg.message),
              if (msg.exception != null)
                LogMessageDetailsField(
                  label: "Exception",
                  content: msg.exception!,
                ),
              LogMessageDetailsField(
                label: "Stack Trace",
                content: msg.stackTrace,
              ),
              LogMessageDetailsField(
                label: "Session",
                content: formatDateTime(msg.sessionStartTime),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LogMessageDetailsField extends StatelessWidget {
  final String label;
  final String content;

  const LogMessageDetailsField({
    super.key,
    required this.label,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: content,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          onPressed: () async {
            try {
              await Clipboard.setData(ClipboardData(text: content));
              if (!context.mounted) return;
              Toast.show(context, "Copied ${label.toLowerCase()}!");
            } catch (e, st) {
              Log.error(
                "failed to add log message field ($label) content to clipboard",
                e: e,
                st: st,
              );
              if (!context.mounted) return;
              Toast.show(context, "Failed to copy ${label.toLowerCase()}!");
            }
          },
          icon: const Icon(Icons.copy),
        ),
      ),
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 14),
      readOnly: true,
      minLines: 1,
      maxLines: 15,
    );
  }
}

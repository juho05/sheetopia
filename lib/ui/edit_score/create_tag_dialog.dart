import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reactive_color_picker/reactive_color_picker.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';
import 'package:sheetopia/ui/edit_score/create_tag_viewmodel.dart';

class CreateTagDialog extends StatelessWidget {
  final CreateTagViewModel viewModel;

  const CreateTagDialog({super.key, required this.viewModel});

  static Future<Tag?> show(BuildContext context, [String? name]) async {
    final viewModel = CreateTagViewModel(
      repo: context.read(),
      initialName: name,
    );
    return await showAdaptiveDialog<Tag>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return CreateTagDialog(viewModel: viewModel);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ReactiveForm(
            formGroup: viewModel.form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Text(
                  "Create tag",
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                ReactiveTextField(
                  formControlName: CreateTagViewModel.formName,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Name",
                  ),
                ),
                ReactiveColorPicker(
                  formControlName: CreateTagViewModel.formColor,
                  enableAlpha: false,
                  hexInputBar: false,
                  displayThumbColor: true,
                  decoration: const InputDecoration(border: InputBorder.none),
                  colorPickerBuilder: (pickColor, color) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (color == null)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text("Color"),
                            onPressed: () => pickColor(),
                          ),
                        if (color != null)
                          FilledButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text("Color"),
                            style: FilledButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: color.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                            ),
                            onPressed: () => pickColor(),
                          ),
                      ],
                    );
                  },
                  colorPickerDialogBuilder: (colorPicker) {
                    return AlertDialog(
                      actions: [
                        FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Select"),
                        ),
                      ],
                      titlePadding: const EdgeInsets.all(0.0),
                      contentPadding: const EdgeInsets.all(0.0),
                      content: SingleChildScrollView(child: colorPicker),
                    );
                  },
                ),
                Row(
                  spacing: 8,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(context, null);
                      },
                      child: const Text("Cancel"),
                    ),
                    ReactiveFormConsumer(
                      builder: (context, form, _) {
                        return FilledButton(
                          onPressed: form.valid
                              ? () async {
                                  final tag = await viewModel.createTag();
                                  if (context.mounted) {
                                    Navigator.pop(context, tag);
                                  }
                                }
                              : null,
                          child: const Text("Create"),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

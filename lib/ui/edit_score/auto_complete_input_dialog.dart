import 'package:flutter/material.dart';

class AutoCompleteInputDialog extends StatefulWidget {
  final String title;
  final String inputLabel;
  final String submitBtnText;
  final Future<Iterable<String>> Function(String filter) getOptions;

  const AutoCompleteInputDialog({
    super.key,
    required this.title,
    required this.inputLabel,
    required this.getOptions,
    required this.submitBtnText,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String inputLabel,
    required String submitBtnText,
    required Future<Iterable<String>> Function(String filter) getOptions,
  }) async {
    return showAdaptiveDialog<String>(
      context: context,
      builder: (context) => AutoCompleteInputDialog(
        title: title,
        inputLabel: inputLabel,
        getOptions: getOptions,
        submitBtnText: submitBtnText,
      ),
      barrierDismissible: true,
    );
  }

  @override
  State<AutoCompleteInputDialog> createState() =>
      _AutoCompleteInputDialogState();
}

class _AutoCompleteInputDialogState extends State<AutoCompleteInputDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _valid = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    bool newValid = _controller.text.trim().isNotEmpty;
    if (newValid != _valid) {
      setState(() {
        _valid = newValid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      constraints: const BoxConstraints(maxWidth: 480),
      insetPadding: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Text(
              widget.title,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall,
            ),
            Autocomplete(
              textEditingController: _controller,
              focusNode: _focusNode,
              fieldViewBuilder:
                  (
                    context,
                    textEditingController,
                    focusNode,
                    onFieldSubmitted,
                  ) {
                    return TextField(
                      autofocus: true,
                      controller: textEditingController,
                      focusNode: focusNode,
                      onSubmitted: (value) {
                        onFieldSubmitted();
                        value = textEditingController.value.text.trim();
                        if (value.isEmpty) return;
                        Navigator.pop(context, value);
                      },
                      decoration: InputDecoration(
                        label: Text(widget.inputLabel),
                        border: const OutlineInputBorder(),
                      ),
                      onTapOutside: (event) => focusNode.unfocus(),
                    );
                  },
              optionsBuilder: (textEditingValue) =>
                  widget.getOptions(textEditingValue.text.trim()),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
                FilledButton(
                  onPressed: _valid
                      ? () {
                          Navigator.pop(context, _controller.text.trim());
                        }
                      : null,
                  child: Text(widget.submitBtnText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

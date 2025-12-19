import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:sheetopia/ui/edit_score/edit_score_form_viewmodel.dart';

class EditScoreForm extends StatelessWidget {
  const EditScoreForm({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => EditScoreFormViewModel(
        editScoreViewModel: context.read(),
        scoresRepo: context.read(),
      ),
      builder: (context, _) {
        return Consumer<EditScoreFormViewModel>(
          builder: (context, viewModel, _) {
            return ReactiveForm(
              formGroup: viewModel.form,
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  ReactiveTextField<String>(
                    formControlName: EditScoreFormViewModel.formTitle,
                    decoration: const InputDecoration(
                      label: Text("Title"),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Autocomplete(
                    optionsBuilder: (textEditingValue) =>
                        viewModel.getComposers(filter: textEditingValue.text),
                    fieldViewBuilder:
                        (
                          context,
                          textEditingController,
                          focusNode,
                          onFieldSubmitted,
                        ) => ReactiveTextField(
                          formControlName: EditScoreFormViewModel.formComposer,
                          controller: textEditingController,
                          focusNode: focusNode,
                          onSubmitted: (control) {
                            onFieldSubmitted();
                          },
                          decoration: const InputDecoration(
                            label: Text("Composer"),
                            border: OutlineInputBorder(),
                          ),
                        ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

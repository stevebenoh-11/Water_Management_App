import 'package:flutter/material.dart';

import 'app_scope.dart';

/// English / தமிழ் segmented switch. Changes apply instantly app-wide.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return SegmentedButton<String>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      segments: [
        ButtonSegment(value: 'en', label: Text(context.tr('languageEnglish'))),
        ButtonSegment(value: 'ta', label: Text(context.tr('languageTamil'))),
      ],
      selected: {app.settings.languageCode},
      onSelectionChanged: (selection) => app.setLanguage(selection.first),
    );
  }
}

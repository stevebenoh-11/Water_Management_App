import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_scope.dart';

/// Validates a positive number. Returns a strings-file key for the error,
/// or null if valid. Kept pure so it can be unit-tested.
String? positiveNumberError(String? input, {double? max}) {
  final text = input?.trim() ?? '';
  if (text.isEmpty) return 'errEmpty';
  final value = double.tryParse(text);
  if (value == null || !value.isFinite) return 'errNotNumber';
  if (value <= 0) return 'errPositive';
  if (max != null && value > max) return 'errTooLarge';
  return null;
}

/// Formats a number without a trailing ".0" (1000.0 → "1000", 0.5 → "0.5").
String formatNumber(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : '$value';

/// Large, labelled numeric input that rejects empty / zero / negative values.
class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.helper,
    this.suffix,
    this.max,
    this.textInputAction = TextInputAction.next,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? helper;
  final String? suffix;
  final double? max;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: Theme.of(context).textTheme.titleMedium,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: textInputAction,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        LengthLimitingTextInputFormatter(8),
      ],
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        prefixIcon: Icon(icon, size: 28),
        suffixText: suffix,
      ),
      validator: (value) {
        final key = positiveNumberError(value, max: max);
        if (key == null) return null;
        return context.tr(key, {'max': max == null ? '' : formatNumber(max!)});
      },
    );
  }
}

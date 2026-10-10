import 'package:flutter/material.dart';

import '../models/tank_profile.dart';
import '../models/user_settings.dart';
import 'app_scope.dart';
import 'tank_labels.dart';

/// City / Town / Village choice with icons and labels.
class AreaPicker extends StatelessWidget {
  const AreaPicker({super.key, required this.value, required this.onChanged});

  final AreaType value;
  final ValueChanged<AreaType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.tr('areaType'),
            style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),
        SegmentedButton<AreaType>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          segments: [
            for (final a in AreaType.values)
              ButtonSegment(
                value: a,
                icon: Icon(areaIcon(a)),
                label: Text(context.tr(areaKey(a))),
              ),
          ],
          selected: {value},
          onSelectionChanged: (s) => onChanged(s.first),
        ),
      ],
    );
  }
}

/// Generic large dropdown with an icon per option.
class LabeledDropdown<T> extends StatelessWidget {
  const LabeledDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.itemIcon,
  });

  final String label;
  final IconData icon;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final IconData Function(T)? itemIcon;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 28),
      ),
      items: [
        for (final item in items)
          DropdownMenuItem(
            value: item,
            child: Row(
              children: [
                if (itemIcon != null) ...[
                  Icon(itemIcon!(item)),
                  const SizedBox(width: 10),
                ],
                Flexible(
                    child:
                        Text(itemLabel(item), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

/// Tank material dropdown.
class MaterialDropdown extends StatelessWidget {
  const MaterialDropdown(
      {super.key, required this.value, required this.onChanged});

  final TankMaterial value;
  final ValueChanged<TankMaterial> onChanged;

  @override
  Widget build(BuildContext context) => LabeledDropdown<TankMaterial>(
        label: context.tr('tankMaterial'),
        icon: materialIcon(value),
        value: value,
        items: TankMaterial.values,
        itemLabel: (m) => context.tr(tankMaterialKey(m)),
        itemIcon: materialIcon,
        onChanged: onChanged,
      );
}

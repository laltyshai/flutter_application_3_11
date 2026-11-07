import 'package:flutter/material.dart';

/// One choice in a [SettingChoice].
class SettingOption<T> {
  const SettingOption(this.value, this.label, this.icon, {this.description});

  final T value;
  final String label;
  final IconData icon;

  /// Shown under the buttons while this option is selected.
  final String? description;
}

/// A setting whose options are all visible at once: a titled card with one
/// segmented button per option. One tap changes the setting; no dialog.
class SettingChoice<T> extends StatelessWidget {
  const SettingChoice({
    super.key,
    required this.icon,
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final List<SettingOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = options.firstWhere((o) => o.value == selected);
    final description = current.description;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Row(
                children: [
                  Icon(icon, color: theme.colorScheme.onSurface),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<T>(
              // Fill the card width so each option is a large tap target.
              expandedInsets: EdgeInsets.zero,
              showSelectedIcon: false,
              segments: [
                for (final o in options)
                  ButtonSegment(
                    value: o.value,
                    icon: Icon(o.icon),
                    label: Text(o.label),
                    tooltip: '$title: ${o.label}',
                  ),
              ],
              selected: {selected},
              onSelectionChanged: (s) => onChanged(s.single),
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text(description, style: theme.textTheme.bodyMedium),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

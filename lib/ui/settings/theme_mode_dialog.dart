import 'package:flutter/material.dart';

/// Theme choices shown in Settings. A new option only needs a new entry.
const themeModeOptions = [
  (mode: ThemeMode.system, label: 'System', icon: Icons.brightness_auto),
  (mode: ThemeMode.light, label: 'Light', icon: Icons.light_mode_outlined),
  (mode: ThemeMode.dark, label: 'Dark', icon: Icons.dark_mode_outlined),
];

/// Display name for [mode], e.g. "Dark".
String themeModeLabel(ThemeMode mode) =>
    themeModeOptions.firstWhere((o) => o.mode == mode).label;

/// Lets the user pick System / Light / Dark. Resolves to the chosen mode,
/// or `null` when dismissed.
Future<ThemeMode?> showThemeModeDialog(
  BuildContext context, {
  required ThemeMode current,
}) => showDialog<ThemeMode>(
  context: context,
  builder: (context) => SimpleDialog(
    title: const Text('Theme'),
    children: [
      for (final option in themeModeOptions)
        ListTile(
          leading: Icon(option.icon),
          title: Text(option.label),
          subtitle: option.mode == ThemeMode.system
              ? const Text('Follow the phone setting')
              : null,
          trailing: option.mode == current ? const Icon(Icons.check) : null,
          selected: option.mode == current,
          onTap: () => Navigator.pop(context, option.mode),
        ),
    ],
  ),
);

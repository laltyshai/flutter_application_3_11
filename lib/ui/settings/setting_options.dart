import 'package:flutter/material.dart';

import '../../data/models/app_settings.dart';
import '../widgets/setting_choice.dart';

/// Choices shown in Settings. A new option only needs a new entry here.
const themeModeOptions = [
  SettingOption(
    ThemeMode.system,
    'System',
    Icons.brightness_auto,
    description: 'Follows your phone\'s light or dark setting.',
  ),
  SettingOption(
    ThemeMode.light,
    'Light',
    Icons.light_mode_outlined,
    description: 'Always light.',
  ),
  SettingOption(
    ThemeMode.dark,
    'Dark',
    Icons.dark_mode_outlined,
    description: 'Always dark.',
  ),
];

const boardLayoutOptions = [
  SettingOption(
    BoardLayout.rows,
    'Rows',
    Icons.view_agenda_outlined,
    description: 'Each status is a row. Swipe cards sideways.',
  ),
  SettingOption(
    BoardLayout.columns,
    'Columns',
    Icons.view_week_outlined,
    description: 'Each status is a column. Swipe between columns.',
  ),
];

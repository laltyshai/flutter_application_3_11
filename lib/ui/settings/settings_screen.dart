import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_settings.dart';
import '../../providers/settings_provider.dart';
import '../backup/backup_screen.dart';
import '../widgets/setting_choice.dart';
import 'setting_options.dart';

/// Settings tab: theme, board layout, and the way into Backup & restore.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SettingChoice<ThemeMode>(
            icon: Icons.palette_outlined,
            title: 'Theme',
            options: themeModeOptions,
            selected: settings.themeMode,
            onChanged: notifier.setThemeMode,
          ),
          const SizedBox(height: 8),
          SettingChoice<BoardLayout>(
            icon: Icons.view_kanban_outlined,
            title: 'Board layout',
            options: boardLayoutOptions,
            selected: settings.boardLayout,
            onChanged: notifier.setBoardLayout,
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.backup_outlined,
            title: 'Backup & restore',
            subtitle: 'Export to JSON/CSV or import a backup',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const BackupScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

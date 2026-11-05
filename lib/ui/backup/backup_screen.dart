import 'package:flutter/material.dart';

import '../widgets/empty_state.dart';

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup')),
      body: const EmptyState(
        icon: Icons.backup_outlined,
        title: 'Backup & restore',
        message: 'Export your data to JSON or CSV, or import a backup.',
      ),
    );
  }
}

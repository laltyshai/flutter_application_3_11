import 'package:flutter/material.dart';

import '../widgets/empty_state.dart';

class BoardScreen extends StatelessWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Board')),
      body: const EmptyState(
        icon: Icons.view_kanban_outlined,
        title: 'No tasks yet',
        message: 'Your Kanban board will show To Do, In Progress and Done columns here.',
      ),
    );
  }
}

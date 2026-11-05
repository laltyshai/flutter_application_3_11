import 'package:flutter/material.dart';

import '../widgets/empty_state.dart';

class MessyCanScreen extends StatelessWidget {
  const MessyCanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messy Can')),
      body: const EmptyState(
        icon: Icons.lightbulb_outline,
        title: 'The can is empty',
        message: 'Dump quick ideas here and promote them to tasks later.',
      ),
    );
  }
}

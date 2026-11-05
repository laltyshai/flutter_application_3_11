import 'package:flutter/material.dart';

import '../widgets/empty_state.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: const EmptyState(
        icon: Icons.calendar_month_outlined,
        title: 'Nothing scheduled',
        message: 'Pick a day to see its tasks and add new ones.',
      ),
    );
  }
}

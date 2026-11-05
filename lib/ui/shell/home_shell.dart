import 'package:flutter/material.dart';

import '../backup/backup_screen.dart';
import '../board/board_screen.dart';
import '../calendar/calendar_screen.dart';
import '../messy_can/messy_can_screen.dart';

/// Bottom navigation with the four main areas of the app.
/// Uses an [IndexedStack] so each tab keeps its scroll/state when switching.
/// Stateful only for the selected tab index, which is local, visual-only state.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = <Widget>[
    BoardScreen(),
    CalendarScreen(),
    MessyCanScreen(),
    BackupScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.view_kanban_outlined),
            selectedIcon: Icon(Icons.view_kanban),
            label: 'Board',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.lightbulb_outline),
            selectedIcon: Icon(Icons.lightbulb),
            label: 'Messy Can',
          ),
          NavigationDestination(
            icon: Icon(Icons.backup_outlined),
            selectedIcon: Icon(Icons.backup),
            label: 'Backup',
          ),
        ],
      ),
    );
  }
}

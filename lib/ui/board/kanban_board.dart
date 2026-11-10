import 'package:flutter/material.dart';

import '../../data/models/task.dart';
import 'kanban_column.dart';

/// Swipeable columns (one page each, neighbors peek in at the sides).
/// While a card is dragged near the left/right edge, the board flips to the
/// neighbor column so the card can be dropped there.
/// Stateful only for the [PageController] and drag auto-scroll timing.
class KanbanBoard extends StatefulWidget {
  const KanbanBoard({
    super.key,
    required this.columns,
    required this.now,
    required this.onOpen,
    required this.onMove,
    this.onDoneChanged,
  });

  final Map<TaskStatus, List<Task>> columns;
  final DateTime now;
  final ValueChanged<Task> onOpen;
  final void Function(Task task, TaskStatus to) onMove;

  /// Called when a card's done checkbox is ticked or cleared.
  final void Function(Task task, bool done)? onDoneChanged;

  /// Width of the edge zone that triggers auto-scroll while dragging.
  static const edgeWidth = 48.0;

  @override
  State<KanbanBoard> createState() => _KanbanBoardState();
}

class _KanbanBoardState extends State<KanbanBoard> {
  final _controller = PageController(viewportFraction: 0.86);

  /// Time since the last auto-scroll, so holding a card at the edge flips
  /// one column at a time instead of racing to the end.
  final _sinceFlip = Stopwatch();
  static const _flipCooldown = Duration(milliseconds: 700);
  static const _flipDuration = Duration(milliseconds: 250);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) => _controller.animateToPage(
    page,
    duration: _flipDuration,
    curve: Curves.easeOut,
  );

  void _onDragUpdate(DragUpdateDetails details) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !_controller.hasClients) return;
    if (_sinceFlip.isRunning && _sinceFlip.elapsed < _flipCooldown) return;

    final x = box.globalToLocal(details.globalPosition).dx;
    final current = _controller.page?.round() ?? 0;
    final int target;
    if (x < KanbanBoard.edgeWidth) {
      target = current - 1;
    } else if (x > box.size.width - KanbanBoard.edgeWidth) {
      target = current + 1;
    } else {
      return;
    }
    if (target < 0 || target >= widget.columns.length) return;
    _sinceFlip
      ..reset()
      ..start();
    _goTo(target);
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.columns.entries.toList();
    return PageView.builder(
      controller: _controller,
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final MapEntry(key: status, value: tasks) = entries[i];
        return Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 12),
          child: KanbanColumn(
            key: ValueKey(status),
            status: status,
            tasks: tasks,
            now: widget.now,
            onOpen: widget.onOpen,
            onMove: widget.onMove,
            onHeaderTap: () => _goTo(i),
            onDragUpdate: _onDragUpdate,
            onDoneChanged: widget.onDoneChanged,
          ),
        );
      },
    );
  }
}

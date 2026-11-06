import 'package:flutter/material.dart';

import '../../core/utils/list_utils.dart';
import '../../data/models/task.dart';
import 'board_parts.dart';

/// Horizontal board: one section per status, stacked vertically. Cards sit
/// in up to two rows and scroll sideways when they don't fit.
/// While a card is dragged near the top/bottom edge, the list scrolls so
/// every status can be reached.
/// Stateful only for the [ScrollController] and drag auto-scroll timing.
class KanbanRows extends StatefulWidget {
  const KanbanRows({
    super.key,
    required this.columns,
    required this.now,
    required this.onOpen,
    required this.onMove,
  });

  final Map<TaskStatus, List<Task>> columns;
  final DateTime now;
  final ValueChanged<Task> onOpen;
  final void Function(Task task, TaskStatus to) onMove;

  /// Cards per status are laid out in at most this many rows.
  static const maxRows = 2;

  /// Height of the edge zone that triggers auto-scroll while dragging.
  static const edgeHeight = 56.0;

  @override
  State<KanbanRows> createState() => _KanbanRowsState();
}

class _KanbanRowsState extends State<KanbanRows> {
  final _controller = ScrollController();
  final _sinceScroll = Stopwatch();
  static const _scrollCooldown = Duration(milliseconds: 400);
  static const _scrollStep = 180.0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !_controller.hasClients) return;
    if (_sinceScroll.isRunning && _sinceScroll.elapsed < _scrollCooldown) {
      return;
    }
    final y = box.globalToLocal(details.globalPosition).dy;
    final double delta;
    if (y < KanbanRows.edgeHeight) {
      delta = -_scrollStep;
    } else if (y > box.size.height - KanbanRows.edgeHeight) {
      delta = _scrollStep;
    } else {
      return;
    }
    final position = _controller.position;
    final target = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (target == position.pixels) return;
    _sinceScroll
      ..reset()
      ..start();
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.columns.entries.toList();
    return ListView.separated(
      controller: _controller,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final MapEntry(key: status, value: tasks) = entries[i];
        return _StatusRow(
          key: ValueKey(status),
          status: status,
          tasks: tasks,
          now: widget.now,
          onOpen: widget.onOpen,
          onMove: widget.onMove,
          onDragUpdate: _onDragUpdate,
        );
      },
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    super.key,
    required this.status,
    required this.tasks,
    required this.now,
    required this.onOpen,
    required this.onMove,
    required this.onDragUpdate,
  });

  final TaskStatus status;
  final List<Task> tasks;
  final DateTime now;
  final ValueChanged<Task> onOpen;
  final void Function(Task task, TaskStatus to) onMove;
  final ValueChanged<DragUpdateDetails> onDragUpdate;

  @override
  Widget build(BuildContext context) {
    return StatusDropTarget(
      status: status,
      onMove: onMove,
      builder: (context, highlighted) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatusHeader(title: status.label, count: tasks.length),
          if (tasks.isEmpty)
            EmptyStatusHint(highlighted: highlighted)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                // Wide enough to read, narrow enough that the next card
                // peeks in and hints at sideways scrolling.
                final cardWidth = (constraints.maxWidth * 0.72).clamp(
                  200.0,
                  320.0,
                );
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final row in splitIntoRows(
                        tasks,
                        KanbanRows.maxRows,
                      ))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final task in row)
                                Padding(
                                  key: ValueKey(task.id),
                                  padding: const EdgeInsets.only(right: 8),
                                  child: SizedBox(
                                    width: cardWidth,
                                    child: DraggableTaskCard(
                                      task: task,
                                      now: now,
                                      width: cardWidth,
                                      onOpen: onOpen,
                                      onDragUpdate: onDragUpdate,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

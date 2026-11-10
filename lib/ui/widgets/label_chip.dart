import 'package:flutter/material.dart';

import '../../core/theme/label_colors.dart';

/// GitHub-style label pill: colored background (fixed per label name) with
/// readable text.
class LabelChip extends StatelessWidget {
  const LabelChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = LabelColors.of(label);
    return Semantics(
      label: 'Label $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: LabelColors.onColor(color),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

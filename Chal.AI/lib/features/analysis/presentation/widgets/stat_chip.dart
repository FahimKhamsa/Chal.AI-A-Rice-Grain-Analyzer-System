// features/analysis/presentation/widgets/stat_chip.dart
// Compact card showing grain count, percentage and color indicator.
import 'package:flutter/material.dart';

class StatChip extends StatelessWidget {
  final String label, value;
  final double pct;
  final Color color;
  final IconData icon;

  const StatChip({
    super.key,
    required this.label,
    required this.value,
    required this.pct,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(80), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                color: color, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          // Mini progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: cs.onSurface.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${pct.toStringAsFixed(1)}%',
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

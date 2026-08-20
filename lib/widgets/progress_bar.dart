import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final int completed;
  final int total;
  final double height;
  final Color? backgroundColor;
  final Color? fillColor;

  const ProgressBar({
    super.key,
    required this.completed,
    required this.total,
    this.height = 6,
    this.backgroundColor,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;
    final color = fillColor ?? _colorForProgress(progress);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Container(
                  color: backgroundColor ?? const Color(0xFFE2E8F0),
                ),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (total > 0) ...[
          const SizedBox(height: 4),
          Text(
            '$completed de $total etapas',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ],
    );
  }

  Color _colorForProgress(double progress) {
    if (progress >= 1.0) return const Color(0xFF16A34A);
    if (progress >= 0.5) return const Color(0xFF2563EB);
    if (progress > 0.0) return const Color(0xFFF59E0B);
    return const Color(0xFF94A3B8);
  }
}

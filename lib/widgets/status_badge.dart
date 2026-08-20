import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory StatusBadge.process(String status) {
    switch (status) {
      case 'active':
        return const StatusBadge(
          label: 'En curso',
          color: Color(0xFF2563EB),
          icon: Icons.play_circle_outline_rounded,
        );
      case 'closed':
        return const StatusBadge(
          label: 'Sellado',
          color: Color(0xFF7C3AED),
          icon: Icons.verified_rounded,
        );
      default:
        return StatusBadge(
          label: status,
          color: const Color(0xFF64748B),
        );
    }
  }

  factory StatusBadge.record(String status) {
    switch (status) {
      case 'confirmed':
        return const StatusBadge(
          label: 'Confirmado',
          color: Color(0xFF16A34A),
          icon: Icons.check_circle_outline_rounded,
        );
      case 'pending':
        return const StatusBadge(
          label: 'Pendiente',
          color: Color(0xFFF59E0B),
          icon: Icons.hourglass_empty_rounded,
        );
      case 'failed':
        return const StatusBadge(
          label: 'Fallido',
          color: Color(0xFFDC2626),
          icon: Icons.error_outline_rounded,
        );
      default:
        return StatusBadge(
          label: status,
          color: const Color(0xFF64748B),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

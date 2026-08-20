import 'package:flutter/material.dart';
import 'package:sse_frontend_mobil/models/process.dart';
import 'package:sse_frontend_mobil/widgets/status_badge.dart';
import 'package:sse_frontend_mobil/widgets/progress_bar.dart';

class ProcessCard extends StatelessWidget {
  final Process process;
  final VoidCallback? onTap;

  const ProcessCard({
    super.key,
    required this.process,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    process.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge.process(process.status),
              ],
            ),
            if (process.clientName != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.business_rounded,
                      size: 13, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      process.clientName!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (process.totalSteps != null && process.totalSteps! > 0) ...[
              const SizedBox(height: 10),
              ProgressBar(
                completed: process.confirmedSteps ?? 0,
                total: process.totalSteps!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

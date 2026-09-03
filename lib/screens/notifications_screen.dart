import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sse_frontend_mobil/models/app_notification.dart';
import 'package:sse_frontend_mobil/providers/auth_provider.dart';
import 'package:sse_frontend_mobil/providers/notification_provider.dart';
import 'package:sse_frontend_mobil/widgets/empty_state.dart';
import 'package:sse_frontend_mobil/widgets/skeleton.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: const Text('Notificaciones',
            style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () async {
                final api = ref.read(apiClientProvider);
                await api.put('/notifications/read-all');
                ref.invalidate(notificationsProvider);
              },
              child: const Text('Marcar todo leído',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const ListSkeleton(count: 6),
        error: (e, _) => EmptyState(
          icon: Icons.notifications_off_rounded,
          title: 'Error al cargar notificaciones',
          actionLabel: 'Reintentar',
          onAction: () => ref.invalidate(notificationsProvider),
        ),
        data: (response) {
          final items = response.notifications;
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'Sin notificaciones',
              message: 'Cuando haya novedades apareceran aqui',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            color: const Color(0xFF1E293B),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _NotificationCard(notification: items[index]),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.read;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isUnread
            ? Border.all(
                color: const Color(0xFFF97316).withValues(alpha: 0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _typeIcon(notification.type),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(notification.title,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  isUnread ? FontWeight.w600 : FontWeight.w500,
                              color: const Color(0xFF1E293B))),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF97316),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                if (notification.body != null &&
                    notification.body!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(notification.body!,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF64748B)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 6),
                Text(_timeAgo(notification.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeIcon(String type) {
    final (color, icon) = switch (type) {
      'step_assigned' => (
          const Color(0xFF2563EB),
          Icons.assignment_rounded,
        ),
      'step_recorded' => (
          const Color(0xFF16A34A),
          Icons.check_circle_outline_rounded,
        ),
      'step_confirmed' => (
          const Color(0xFF7C3AED),
          Icons.verified_rounded,
        ),
      'process_closed' => (
          const Color(0xFF7C3AED),
          Icons.lock_outline_rounded,
        ),
      'comment' => (
          const Color(0xFF0EA5E9),
          Icons.chat_bubble_outline_rounded,
        ),
      _ => (
          const Color(0xFF64748B),
          Icons.notifications_none_rounded,
        ),
    };

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  String _timeAgo(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    return '${date.day}/${date.month}/${date.year}';
  }
}

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sse_frontend_mobil/models/app_notification.dart';
import 'package:sse_frontend_mobil/providers/auth_provider.dart';

class NotificationsResponse {
  final List<AppNotification> notifications;
  final int unread;

  const NotificationsResponse({required this.notifications, required this.unread});
}

final notificationsProvider =
    FutureProvider<NotificationsResponse>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get('/notifications');
  final body = jsonDecode(response.body) as Map<String, dynamic>;
  final list = (body['notifications'] as List)
      .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
      .toList();
  return NotificationsResponse(
    notifications: list,
    unread: body['unread'] as int? ?? 0,
  );
});

final unreadCountProvider = Provider<int>((ref) {
  final async = ref.watch(notificationsProvider);
  return async.whenOrNull(data: (r) => r.unread) ?? 0;
});

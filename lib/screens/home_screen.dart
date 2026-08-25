import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sse_frontend_mobil/config/app_theme.dart';
import 'package:sse_frontend_mobil/models/user.dart';
import 'package:sse_frontend_mobil/providers/auth_provider.dart';
import 'package:sse_frontend_mobil/providers/notification_provider.dart';
import 'package:sse_frontend_mobil/providers/process_provider.dart';
import 'package:sse_frontend_mobil/widgets/process_card.dart';
import 'package:sse_frontend_mobil/widgets/quick_action_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1E293B)),
        ),
      );
    }

    if (!authState.isAuthenticated || authState.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const SizedBox.shrink();
    }

    final user = authState.user!;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text(
          'SSE',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.5),
        ),
        actions: [
          _NotificationBell(),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(processListProvider.notifier).refresh();
        },
        color: const Color(0xFF1E293B),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildProfileHeader(user),
            const SizedBox(height: 20),
            if (user.isAdmin || user.isCoordinador) ...[
              _buildAdminActions(context, user),
            ] else if (user.isOperario) ...[
              _buildOperarioActions(context, ref),
            ] else ...[
              _buildAuditorActions(context, ref),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email ?? user.username,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF97316).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _roleLabel(user.role),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF97316),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.coordinador:
        return 'COORDINADOR';
      case UserRole.operario:
        return 'OPERARIO';
      case UserRole.auditor:
        return 'AUDITOR';
    }
  }

  Widget _buildAdminActions(BuildContext context, User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones rapidas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
              QuickActionCard(
                icon: Icons.assignment_rounded,
                label: 'Procesos',
                subtitle: 'Ver todos',
                color: const Color(0xFF2563EB),
                onTap: () => context.push('/processes'),
              ),
              if (user.isAdmin || user.isCoordinador) ...[
                QuickActionCard(
                  icon: Icons.add_task_rounded,
                  label: 'Crear proceso',
                  subtitle: 'Nuevo',
                  color: const Color(0xFFF97316),
                  onTap: () => context.push('/create-process'),
                ),
                QuickActionCard(
                  icon: Icons.people_rounded,
                  label: 'Usuarios',
                  subtitle: 'Gestionar',
                  color: const Color(0xFF7C3AED),
                  onTap: () => context.push('/admin/users'),
                ),
              QuickActionCard(
                icon: Icons.analytics_rounded,
                label: 'Metricas',
                subtitle: 'Ver estadisticas',
                color: const Color(0xFF059669),
                onTap: () {},
              ),
              QuickActionCard(
                icon: Icons.description_rounded,
                label: 'Plantillas',
                subtitle: 'Crear/editar',
                color: const Color(0xFFF97316),
                onTap: () {},
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildOperarioActions(BuildContext context, WidgetRef ref) {
    final processState = ref.watch(processListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mis procesos',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        processState.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: Color(0xFF1E293B)),
            ),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      size: 40, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 12),
                  const Text(
                    'Sin conexion',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Desliza para reintentar',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          ),
          data: (processes) {
            if (processes.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(Icons.assignment_turned_in_rounded,
                          size: 40, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 12),
                      const Text(
                        'Sin procesos asignados',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final active =
                processes.where((p) => !p.isClosed).toList();
            final closed =
                processes.where((p) => p.isClosed).toList();

            return Column(
              children: [
                if (active.isNotEmpty) ...[
                  ...active.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ProcessCard(
                          process: p,
                          onTap: () => context.push('/process/${p.id}'),
                        ),
                      )),
                ],
                if (closed.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Completados',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...closed.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ProcessCard(
                          process: p,
                          onTap: () => context.push('/process/${p.id}'),
                        ),
                      )),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAuditorActions(BuildContext context, WidgetRef ref) {
    final processState = ref.watch(processListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Procesos para auditar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        processState.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: Color(0xFF1E293B)),
            ),
          ),
          error: (e, _) => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Error al cargar procesos',
                  style: TextStyle(color: Color(0xFF64748B))),
            ),
          ),
          data: (processes) {
            if (processes.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No hay procesos disponibles',
                      style: TextStyle(color: Color(0xFF94A3B8))),
                ),
              );
            }
            return Column(
              children: processes
                  .map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ProcessCard(
                          process: p,
                          onTap: () => context.push('/process/${p.id}'),
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () => context.push('/notifications'),
        ),
        if (unread > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: const BoxDecoration(
                color: Color(0xFFF97316),
                shape: BoxShape.circle,
              ),
              child: Text(
                unread > 9 ? '9+' : '$unread',
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

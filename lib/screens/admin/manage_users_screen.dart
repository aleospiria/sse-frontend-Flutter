import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sse_frontend_mobil/config/app_theme.dart';
import 'package:sse_frontend_mobil/models/user.dart';
import 'package:sse_frontend_mobil/providers/auth_provider.dart';
import 'package:sse_frontend_mobil/providers/users_provider.dart';
import 'package:sse_frontend_mobil/widgets/skeleton.dart';

class ManageUsersScreen extends ConsumerWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text('Usuarios',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: Colors.white),
            onPressed: () => _showAuditLog(context, ref),
            tooltip: 'Auditoria',
          ),
        ],
      ),
      body: usersAsync.when(
        loading: () => const ListSkeleton(count: 5),
        error: (e, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 48, color: AppTheme.textLight),
                SizedBox(height: 16),
                Text('Error: $e',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => ref.read(usersProvider.notifier).refresh(),
                  icon: Icon(Icons.refresh_rounded, size: 18),
                  label: Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline_rounded,
                      size: 44, color: Color(0xFF94A3B8)),
                  SizedBox(height: 16),
                  Text('Sin usuarios',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B))),
                  SizedBox(height: 8),
                  Text('Crea el primer usuario con el boton +',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ],
              ),
            );
          }

          final grouped = _groupByRole(users);

          return RefreshIndicator(
            onRefresh: () => ref.read(usersProvider.notifier).refresh(),
            color: AppTheme.primaryDark,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                for (final entry in grouped.entries) ...[
                  _sectionHeader(entry.key, entry.value.length),
                  SizedBox(height: 8),
                  for (final user in entry.value)
                    _UserCard(
                      user: user,
                      onTap: () => _showUserDetail(context, ref, user),
                    ),
                  SizedBox(height: 12),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        icon: Icon(Icons.person_add_rounded, size: 20),
        label: Text('Nuevo usuario',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Map<UserRole, List<User>> _groupByRole(List<User> users) {
    final order = [UserRole.admin, UserRole.coordinador, UserRole.operario, UserRole.auditor];
    final map = <UserRole, List<User>>{};
    for (final role in order) {
      final filtered = users.where((u) => u.role == role).toList();
      if (filtered.isNotEmpty) map[role] = filtered;
    }
    return map;
  }

  Widget _sectionHeader(UserRole role, int count) {
    final colors = AppTheme.roleColors[role]!;
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: colors.badgeBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(colors.label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: colors.badge)),
        ),
        SizedBox(width: 8),
        Text('$count',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textLight)),
      ],
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CreateUserSheet(),
    );
  }

  void _showUserDetail(BuildContext context, WidgetRef ref, User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _UserDetailSheet(user: user),
    );
  }

  void _showAuditLog(BuildContext context, WidgetRef ref) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _AuditLogScreen()));
  }
}

// ─── User Card ────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const _UserCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.roleColors[user.role]!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: colors.badgeBg,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: colors.badge),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark)),
                  SizedBox(height: 2),
                  Text(user.email ?? user.username,
                      style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colors.badgeBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(colors.label,
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700, color: colors.badge)),
            ),
            SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }
}

// ─── Create User Sheet ────────────────────────────────────

class _CreateUserSheet extends ConsumerStatefulWidget {
  const _CreateUserSheet();

  @override
  ConsumerState<_CreateUserSheet> createState() => _CreateUserSheetState();
}

class _CreateUserSheetState extends ConsumerState<_CreateUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  UserRole _role = UserRole.operario;
  String? _industry;
  bool _loading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Crear usuario',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark)),
              SizedBox(height: 20),
              TextFormField(
                controller: _usernameCtrl,
                decoration: InputDecoration(
                    labelText: 'Usuario *',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20)),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.badge_outlined, size: 20)),
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email_outlined, size: 20)),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (!v.contains('@')) return 'Email invalido';
                  return null;
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                decoration: InputDecoration(
                    labelText: 'Contraseña (dejar vacio = invitation)',
                    prefixIcon: Icon(Icons.lock_outline_rounded, size: 20)),
                obscureText: true,
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                initialValue: _role,
                decoration: InputDecoration(
                    labelText: 'Rol',
                    prefixIcon: Icon(Icons.admin_panel_settings_outlined, size: 20)),
                items: UserRole.values
                    .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(AppTheme.roleColors[r]!.label,
                            style: TextStyle(fontSize: 14))))
                    .toList(),
                onChanged: (v) => setState(() => _role = v ?? UserRole.operario),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Crear usuario'),
              ),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(usersProvider.notifier).create(
            username: _usernameCtrl.text.trim(),
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            role: _role,
            industry: _industry,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Usuario creado'),
            backgroundColor: Color(0xFF10B981)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Color(0xFFEF4444)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─── User Detail Sheet ────────────────────────────────────

class _UserDetailSheet extends ConsumerWidget {
  final User user;

  const _UserDetailSheet({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.roleColors[user.role]!;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colors.badgeBg,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700, color: colors.badge),
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark)),
                    Text(user.email ?? user.username,
                        style: TextStyle(fontSize: 13, color: AppTheme.textLight)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.badgeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(colors.label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: colors.badge)),
          ),
          SizedBox(height: 20),
          _DetailAction(
            icon: Icons.edit_rounded,
            label: 'Editar usuario',
            color: AppTheme.primaryDark,
            onTap: () {
              Navigator.pop(context);
              _showEditSheet(context, ref);
            },
          ),
          if (user.isOperario) ...[
            _DetailAction(
              icon: Icons.assignment_ind_rounded,
              label: 'Ver asignaciones',
              color: Color(0xFF3B82F6),
              onTap: () {
                Navigator.pop(context);
                _showAssignments(context, ref);
              },
            ),
            _DetailAction(
              icon: Icons.history_rounded,
              label: 'Ver actividad',
              color: Color(0xFF8B5CF6),
              onTap: () {
                Navigator.pop(context);
                _showActivity(context, ref);
              },
            ),
            _DetailAction(
              icon: Icons.link_off_rounded,
              label: 'Desasignar todo',
              color: Color(0xFFF97316),
              onTap: () => _unassignAll(context, ref),
            ),
          ],
          _DetailAction(
            icon: Icons.delete_outline_rounded,
            label: 'Eliminar usuario',
            color: Color(0xFFEF4444),
            onTap: () => _confirmDelete(context, ref),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EditUserSheet(user: user),
    );
  }

  void _showAssignments(BuildContext context, WidgetRef ref) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => _UserAssignmentsScreen(user: user)));
  }

  void _showActivity(BuildContext context, WidgetRef ref) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => _UserActivityScreen(user: user)));
  }

  Future<void> _unassignAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Desasignar todo'),
        content: Text('Se removeran todas las asignaciones de ${user.name}. Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Confirmar', style: TextStyle(color: Color(0xFFF97316)))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        final api = ref.read(apiClientProvider);
        await api.post('/auth/users/${user.id}/unassign-all');
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Todas las asignaciones removidas'),
              backgroundColor: Color(0xFF10B981)));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Color(0xFFEF4444)));
        }
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar usuario'),
        content: Text('Eliminar a ${user.name}? Esta accion no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Eliminar', style: TextStyle(color: Color(0xFFEF4444)))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await ref.read(usersProvider.notifier).delete(user.id);
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Usuario eliminado'),
              backgroundColor: Color(0xFF10B981)));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Color(0xFFEF4444)));
        }
      }
    }
  }
}

class _DetailAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DetailAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        margin: EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            SizedBox(width: 12),
            Text(label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}

// ─── Edit User Sheet ──────────────────────────────────────

class _EditUserSheet extends ConsumerStatefulWidget {
  final User user;

  const _EditUserSheet({required this.user});

  @override
  ConsumerState<_EditUserSheet> createState() => _EditUserSheetState();
}

class _EditUserSheetState extends ConsumerState<_EditUserSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  late UserRole _role;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.user.username);
    _nameCtrl = TextEditingController(text: widget.user.name);
    _emailCtrl = TextEditingController(text: widget.user.email ?? '');
    _passwordCtrl = TextEditingController();
    _role = widget.user.role;
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Editar usuario',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark)),
              SizedBox(height: 20),
              TextFormField(
                controller: _usernameCtrl,
                decoration: InputDecoration(
                    labelText: 'Usuario *',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.badge_outlined, size: 20)),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email_outlined, size: 20)),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (!v.contains('@')) return 'Email invalido';
                  return null;
                },
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<UserRole>(
                initialValue: _role,
                decoration: InputDecoration(
                    labelText: 'Rol',
                    prefixIcon: Icon(Icons.admin_panel_settings_outlined, size: 20)),
                items: UserRole.values
                    .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(AppTheme.roleColors[r]!.label,
                            style: TextStyle(fontSize: 14))))
                    .toList(),
                onChanged: (v) => setState(() => _role = v ?? UserRole.operario),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                decoration: InputDecoration(
                    labelText: 'Nueva contraseña (opcional)',
                    prefixIcon: Icon(Icons.lock_outline_rounded, size: 20)),
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Guardar cambios'),
              ),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final result = await ref.read(usersProvider.notifier).update(
            widget.user.id,
            username: _usernameCtrl.text.trim(),
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            role: _role,
            password: _passwordCtrl.text,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result.cognitoWarning ?? 'Usuario actualizado'),
            backgroundColor: result.cognitoWarning != null
                ? Color(0xFFF97316)
                : Color(0xFF10B981)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Color(0xFFEF4444)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─── User Assignments Screen ──────────────────────────────

class _UserAssignmentsScreen extends ConsumerWidget {
  final User user;

  const _UserAssignmentsScreen({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(userAssignmentsProvider(user.id));

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text('Asignaciones de ${user.name}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: assignmentsAsync.when(
        loading: () => Center(
            child: CircularProgressIndicator(color: AppTheme.primaryDark)),
        error: (e, _) =>
            Center(child: Text('Error: $e', style: TextStyle(color: AppTheme.textMuted))),
        data: (assignments) {
          if (assignments.isEmpty) {
            return Center(
              child: Text('Sin asignaciones',
                  style: TextStyle(color: AppTheme.textLight, fontSize: 14)),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: assignments.length,
            itemBuilder: (context, i) {
              final a = assignments[i];
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a['name'] ?? 'Sin nombre',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark)),
                    SizedBox(height: 4),
                    Text('Proceso: ${a['process_name'] ?? a['process_id'] ?? ''}',
                        style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
                    Text('Paso #${a['order_index'] ?? ''}',
                        style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── User Activity Screen ─────────────────────────────────

class _UserActivityScreen extends ConsumerWidget {
  final User user;

  const _UserActivityScreen({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(userActivityProvider(user.id));

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text('Actividad de ${user.name}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: activityAsync.when(
        loading: () => Center(
            child: CircularProgressIndicator(color: AppTheme.primaryDark)),
        error: (e, _) =>
            Center(child: Text('Error: $e', style: TextStyle(color: AppTheme.textMuted))),
        data: (activity) {
          final records =
              (activity['records'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          if (records.isEmpty) {
            return Center(
              child: Text('Sin actividad registrada',
                  style: TextStyle(color: AppTheme.textLight, fontSize: 14)),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, i) {
              final r = records[i];
              final status = r['status'] ?? 'pending';
              final statusColor = switch (status) {
                'confirmed' => Color(0xFF10B981),
                'failed' => Color(0xFFEF4444),
                _ => Color(0xFFF97316),
              };
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(r['step_name'] ?? 'Paso',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark)),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(status,
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(r['process_name'] ?? '',
                        style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
                    if (r['data_hash'] != null) ...[
                      SizedBox(height: 4),
                      Text('Hash: ${r['data_hash'].toString().substring(0, 16)}...',
                          style: TextStyle(
                              fontSize: 10, color: AppTheme.textLight, fontFamily: 'monospace')),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Audit Log Screen ─────────────────────────────────────

class _AuditLogScreen extends ConsumerWidget {
  const _AuditLogScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logAsync = ref.watch(auditLogProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text('Auditoria',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: logAsync.when(
        loading: () => Center(
            child: CircularProgressIndicator(color: AppTheme.primaryDark)),
        error: (e, _) =>
            Center(child: Text('Error: $e', style: TextStyle(color: AppTheme.textMuted))),
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Text('Sin registros',
                  style: TextStyle(color: AppTheme.textLight, fontSize: 14)),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, i) {
              final log = logs[i];
              final action = log['action'] ?? '';
              final icon = _actionIcon(action);
              final color = _actionColor(action);

              return Container(
                margin: EdgeInsets.only(bottom: 6),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 18, color: color),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_actionLabel(action),
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                          SizedBox(height: 2),
                          Text(log['actor_name'] ?? '',
                              style: TextStyle(fontSize: 12, color: AppTheme.textDark)),
                          if (log['target_name'] != null)
                            Text('→ ${log['target_name']}',
                                style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
                        ],
                      ),
                    ),
                    Text(_timeAgo(log['created_at']),
                        style: TextStyle(fontSize: 10, color: AppTheme.textLight)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _actionIcon(String action) => switch (action) {
        'user_created' => Icons.person_add_rounded,
        'user_updated' => Icons.edit_rounded,
        'user_deleted' => Icons.person_remove_rounded,
        'user_steps_unassigned' => Icons.link_off_rounded,
        _ => Icons.info_outline_rounded,
      };

  Color _actionColor(String action) => switch (action) {
        'user_created' => Color(0xFF10B981),
        'user_updated' => Color(0xFF3B82F6),
        'user_deleted' => Color(0xFFEF4444),
        'user_steps_unassigned' => Color(0xFFF97316),
        _ => AppTheme.textLight,
      };

  String _actionLabel(String action) => switch (action) {
        'user_created' => 'Usuario creado',
        'user_updated' => 'Usuario editado',
        'user_deleted' => 'Usuario eliminado',
        'user_steps_unassigned' => 'Desasignado',
        _ => action,
      };

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    final date = DateTime.tryParse(iso);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    return '${date.day}/${date.month}';
  }
}

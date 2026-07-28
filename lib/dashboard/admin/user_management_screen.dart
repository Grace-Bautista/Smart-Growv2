import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_grow_code/auth/app_user.dart';
import 'package:smart_grow_code/auth/role_guard.dart';
import 'package:smart_grow_code/custom_header_button.dart';
import 'package:smart_grow_code/dashboard/admin/user_form_dialog.dart';
import 'package:smart_grow_code/services/user_management_service.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allow: (user) => user.isAdmin,
      child: const _UserManagementBody(),
    );
  }
}

class _UserManagementBody extends StatefulWidget {
  const _UserManagementBody();

  @override
  State<_UserManagementBody> createState() => _UserManagementBodyState();
}

class _UserManagementBodyState extends State<_UserManagementBody> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F2),
      body: SafeArea(
        child: Column(
          children: [
            CustomHeaderButton(
              title: 'User Management',
              onBack: () => Navigator.pop(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _createStaff,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Create Staff'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB68C63),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<AppUser>>(
                stream: UserManagementService.watchUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(child: Text('Unable to load users.'));
                  }

                  final users = snapshot.data ?? const <AppUser>[];
                  if (users.isEmpty) {
                    return const Center(child: Text('No users found.'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _UserTile(
                        user: users[index],
                        busy: _busy,
                        onEdit: () => _editStaff(users[index]),
                        onDeactivate: () => _confirmAction(
                          title: 'Deactivate user?',
                          message:
                              'This will prevent ${users[index].email} from logging in.',
                          action: () => UserManagementService.deactivateUser(
                            users[index].uid,
                          ),
                        ),
                        onReactivate: () => _confirmAction(
                          title: 'Reactivate user?',
                          message:
                              'This will allow ${users[index].email} to log in again.',
                          action: () => UserManagementService.reactivateUser(
                            users[index].uid,
                          ),
                        ),
                        onDelete: () => _confirmAction(
                          title: 'Delete user?',
                          message:
                              'This permanently deletes ${users[index].email}. Audit logs are preserved.',
                          action: () => UserManagementService.deleteUser(
                            users[index].uid,
                          ),
                        ),
                        onResetPassword: () => _resetPassword(users[index]),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createStaff() async {
    final result = await showDialog<StaffUserFormResult>(
      context: context,
      builder: (_) => const StaffUserFormDialog(),
    );
    if (result == null) return;

    await _runAction(
      () => UserManagementService.createStaff(
        name: result.name,
        email: result.email,
        password: result.password ?? '',
      ),
      successMessage: 'Staff account created.',
    );
  }

  Future<void> _editStaff(AppUser user) async {
    final result = await showDialog<StaffUserFormResult>(
      context: context,
      builder: (_) => StaffUserFormDialog(user: user),
    );
    if (result == null) return;

    await _runAction(
      () => UserManagementService.updateStaff(
        uid: user.uid,
        name: result.name,
        email: result.email,
      ),
      successMessage: 'Staff information updated.',
    );
  }

  Future<void> _confirmAction({
    required String title,
    required String message,
    required Future<void> Function() action,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await _runAction(action, successMessage: 'User updated.');
  }

  Future<void> _resetPassword(AppUser user) async {
    await _runAction(() async {
      await UserManagementService.resetStaffPassword(user.email);
    }, successMessage: 'Password reset email has been sent.');
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(error)),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '');
    return text.isEmpty ? 'Action failed.' : text;
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.busy,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
    required this.onDelete,
    required this.onResetPassword,
  });

  final AppUser user;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;
  final VoidCallback onReactivate;
  final VoidCallback onDelete;
  final VoidCallback onResetPassword;

  @override
  Widget build(BuildContext context) {
    final active = user.status == 'active';
    final canManage = user.isStaff;
    final statusColor = active ? Colors.green : Colors.redAccent;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFB68C63),
                  child: Text(
                    user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name.isEmpty ? user.email : user.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(user.role.toUpperCase()),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  active ? 'Active' : 'Inactive',
                  style: TextStyle(color: statusColor),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canManage) ...[
                  OutlinedButton.icon(
                    onPressed: busy ? null : onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : onResetPassword,
                    icon: const Icon(Icons.lock_reset, size: 18),
                    label: const Text('Reset'),
                  ),
                  if (active)
                    OutlinedButton.icon(
                      onPressed: busy ? null : onDeactivate,
                      icon: const Icon(Icons.block, size: 18),
                      label: const Text('Deactivate'),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: busy ? null : onReactivate,
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Reactivate'),
                    ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : onDelete,
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                  ),
                ] else
                  const Text(
                    'Admin account',
                    style: TextStyle(color: Colors.black54),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

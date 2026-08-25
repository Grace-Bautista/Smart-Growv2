import 'package:flutter/material.dart';
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
                              'This permanently deletes this account. This action cannot be undone.',
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
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFB68C63),
                  child: Text(
                    user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canManage) ...[
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'status') {
                        if (active) {
                          onDeactivate();
                        } else {
                          onReactivate();
                        }
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(
                        value: 'status',
                        child: Text(active ? 'Deactivate' : 'Reactivate'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EADF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Icon(Icons.circle, size: 8, color: statusColor),

                const SizedBox(width: 6),

                Text(
                  active ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (canManage)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onResetPassword,
                  icon: const Icon(Icons.lock_reset, size: 18),
                  label: const Text('Reset Password'),
                ),
              )
            else
              const Text(
                'Admin account',
                style: TextStyle(color: Colors.black54),
              ),
          ],
        ),
      ),
    );
  }
}

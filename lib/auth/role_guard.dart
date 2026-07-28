import 'package:flutter/material.dart';
import 'package:smart_grow_code/auth/app_user.dart';
import 'package:smart_grow_code/auth/auth_service.dart';

class RoleGuard extends StatelessWidget {
  const RoleGuard({
    super.key,
    required this.allow,
    required this.child,
  });

  final bool Function(AppUser user) allow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser>(
      future: AuthService.currentAppUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (snapshot.hasError || user == null || !allow(user)) {
          return Scaffold(
            appBar: AppBar(title: const Text('Access denied')),
            body: const Center(
              child: Text('You do not have permission to access this page.'),
            ),
          );
        }

        return child;
      },
    );
  }
}

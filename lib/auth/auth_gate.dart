import 'package:flutter/material.dart';
import 'package:smart_grow_code/auth/app_user.dart';
import 'package:smart_grow_code/auth/auth_service.dart';
import 'package:smart_grow_code/dashboard/dashboard.dart';
import 'package:smart_grow_code/dashboard/login_screen.dart';
import 'package:smart_grow_code/dashboard/splash_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (snapshot.hasError) {
          return LoginScreen(
            initialMessage: snapshot.error.toString(),
          );
        }

        if (snapshot.data == null) {
          return const LoginScreen();
        }

        return const SmartGrowDashboard();
      },
    );
  }
}

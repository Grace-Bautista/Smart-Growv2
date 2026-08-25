import 'package:flutter/material.dart';
import 'package:smart_grow_code/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryLight, AppTheme.primaryContainer],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 42,
                backgroundImage: AssetImage('assets/images/adhika_logo.jpg'),
              ),
              SizedBox(height: AppTheme.space5),
              Text(
                'Smart Grow',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDark,
                ),
              ),
              SizedBox(height: AppTheme.space5),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

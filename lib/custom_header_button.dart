import 'package:flutter/material.dart';
import 'package:smart_grow_code/theme/app_theme.dart';

class CustomHeaderButton extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  const CustomHeaderButton({super.key, required this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space3),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          boxShadow: AppTheme.softShadow(),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack ?? () => Navigator.pop(context),
            ),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

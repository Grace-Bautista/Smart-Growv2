import 'package:flutter/material.dart';

/// ===========================
/// MAIN BUTTON WIDGET
/// ===========================
class CustomPowerButton extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const CustomPowerButton({super.key, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final height = media.size.height;

    final base = width * 0.045;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 0, // edge-to-edge
        vertical: height * 0.015,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 50, maxWidth: 600),
          padding: EdgeInsets.symmetric(vertical: base * 0.7),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.brown.shade400, Colors.brown.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(base),
            border: Border.all(color: Colors.white24, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.power_settings_new,
                  size: base * 1.2,
                  color: Colors.white,
                ),
                SizedBox(width: base * 0.5),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: base,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        blurRadius: 2,
                        color: Colors.black45,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ===========================
/// UTILITY CLASS (OPTION 3 ✅)
/// ===========================
class ButtonUtils {
  static Widget floatingPowerButton({
    required BuildContext context,
    required String title,
    required VoidCallback onTap,
    double horizontalMargin = 0, // full width by default
    double bottomMargin = 20,
  }) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: CustomPowerButton(title: title, onTap: onTap),
      ),
    );
  }
}

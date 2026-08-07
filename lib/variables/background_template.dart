import 'package:flutter/material.dart';

class BackgroundTemplate extends StatelessWidget {
  const BackgroundTemplate({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Image.asset(
        "assets/images/background-image.jpg",
        fit: BoxFit.cover,
      ),
    );
  }
}

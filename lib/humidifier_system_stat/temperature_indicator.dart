import 'package:flutter/material.dart';

class TemperatureIndicator extends StatelessWidget {
  final double temperature;

  const TemperatureIndicator({
    super.key,
    required this.temperature,
  });

  static const double minTemp = 0;
  static const double maxTemp = 45;

  Color get statusColor {
    if (temperature < 18) {
      return Colors.blue;
    } else if (temperature <= 30) {
      return Colors.green;
    } else if (temperature <= 35) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final percent =
        ((temperature - minTemp) / (maxTemp - minTemp)).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          children: [
            const Text(
              "Temperature",
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              "${temperature.toStringAsFixed(1)}°C",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: statusColor,
                fontSize: 16,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              clipBehavior: Clip.none,
              children: [

                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [
                        Colors.blue,
                        Colors.lightBlue,
                        Colors.green,
                        Colors.green,
                        Colors.yellow,
                        Colors.orange,
                        Colors.red,
                      ],
                    ),
                  ),
                ),

                AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  left: constraints.maxWidth * percent - 1.5,
                  top: -6,
                  child: Container(
                    width: 3,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text("0°C"),
            Text("15"),
            Text("25"),
            Text("35"),
            Text("45+"),
          ],
        ),
      ],
    );
  }
}

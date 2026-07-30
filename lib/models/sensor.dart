import 'package:flutter/material.dart';

/// Represents a single environment sensor reading (Humidity, Temp, CO2...).
///
/// Kept intentionally simple and immutable — the dashboard only ever
/// displays a snapshot of sensor values, it doesn't mutate them directly.
@immutable
class Sensor {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final bool hasInfo;

  const Sensor({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    this.hasInfo = false,
  });
}

/// Simple on/off/auto mode used by the humidifier's "Refill water" control.
enum RefillMode { on, off, auto }

extension RefillModeLabel on RefillMode {
  String get label {
    switch (this) {
      case RefillMode.on:
        return 'On';
      case RefillMode.off:
        return 'Off';
      case RefillMode.auto:
        return 'Auto';
    }
  }
}

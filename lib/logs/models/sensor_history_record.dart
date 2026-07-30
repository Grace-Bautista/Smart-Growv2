class SensorHistoryRecord {
  const SensorHistoryRecord({
    required this.id,
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.co2,
  });

  final String id;
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final double co2;
}

class HarvestRecord {
  const HarvestRecord({
    required this.name,
    required this.date,
    required this.grams,
    required this.estimatedPrice,
  });
  final String name;
  final DateTime date;
  final double grams;
  final double estimatedPrice;

  factory HarvestRecord.fromHive(Object? value) {
    final map = value is Map
        ? Map<Object?, Object?>.from(value)
        : const <Object?, Object?>{};
    return HarvestRecord(
      name: map['name']?.toString() ?? 'Unnamed harvest',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      grams:
          (map['grams'] as num?)?.toDouble() ??
          double.tryParse(map['grams']?.toString() ?? '') ??
          0,
      estimatedPrice:
          (map['price'] as num?)?.toDouble() ??
          double.tryParse(map['price']?.toString() ?? '') ??
          0,
    );
  }

  Map<String, dynamic> toHive() => {
    'name': name,
    'date': date.toIso8601String().split('T').first,
    'grams': grams,
    'price': estimatedPrice,
  };
}

import 'package:firebase_database/firebase_database.dart';
import 'package:smart_grow_code/models/sensor_data.dart';

/// The single Firebase access point for the Smart Grow device's live data.
/// Widgets should use this service instead of importing firebase_database.
class SensorService {
  SensorService({
    FirebaseDatabase? database,
    this.deviceId = defaultDeviceId,
  }) : _database = database ?? FirebaseDatabase.instance;

  static const String defaultDeviceId = 'smartGrow01';

  final FirebaseDatabase _database;
  final String deviceId;

  DatabaseReference get _deviceReference =>
      _database.ref('liveData/$deviceId');

  /// Emits a new typed device state whenever Firebase changes this device node.
  Stream<SensorData> watchLiveData() {
    return _deviceReference.onValue.map(
      (event) => SensorData.fromRealtimeValue(event.snapshot.value),
    );
  }
}

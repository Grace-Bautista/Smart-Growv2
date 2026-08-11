import 'package:firebase_database/firebase_database.dart';

import 'package:smart_grow_code/models/sensor_data.dart';

/// Authoritative RTDB live-state service.
///
/// Every listener receives Firebase's current live value when it subscribes.
/// The service never polls the ESP32 directly.
class SensorService {
  SensorService({FirebaseDatabase? database, this.deviceId = defaultDeviceId})
    : _database = database ?? FirebaseDatabase.instance;

  static const String defaultDeviceId = 'smartGrow01';

  static final SensorService instance = SensorService();

  final FirebaseDatabase _database;
  final String deviceId;

  DatabaseReference get _deviceReference => _database.ref('liveData/$deviceId');

  Stream<SensorData> watchLiveData() {
    return _deviceReference.onValue.map((event) {
      return SensorData.fromRealtimeValue(event.snapshot.value);
    });
  }
}

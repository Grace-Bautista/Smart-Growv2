import 'package:firebase_database/firebase_database.dart';
import 'package:smart_grow_code/models/sensor_data.dart';

/// Authoritative RTDB live-state service. It never polls the ESP32 directly.
class SensorService {
  SensorService({FirebaseDatabase? database, this.deviceId = defaultDeviceId})
      : _database = database ?? FirebaseDatabase.instance;

  static const String defaultDeviceId = 'smartGrow01';
  static final SensorService instance = SensorService();
  final FirebaseDatabase _database;
  final String deviceId;
  Stream<SensorData>? _liveData;

  DatabaseReference get _deviceReference => _database.ref('liveData/$deviceId');

  Stream<SensorData> watchLiveData() => _liveData ??= _deviceReference.onValue
      .map((event) => SensorData.fromRealtimeValue(event.snapshot.value))
      .asBroadcastStream();
}

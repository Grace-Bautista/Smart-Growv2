import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_grow_code/models/iot_command.dart';

class IotCommandService extends ChangeNotifier {
  IotCommandService({FirebaseDatabase? database, this.deviceId = 'smartGrow01'}) : _database = database ?? FirebaseDatabase.instance;
  static final instance = IotCommandService();
  static const int ttlMs = 5000;
  final FirebaseDatabase _database;
  final String deviceId;
  final Map<IotCommandTarget, IotCommandState> _states = {};
  final Map<IotCommandTarget, StreamSubscription<DatabaseEvent>> _subscriptions = {};
  final Set<IotCommandTarget> _submitting = {};

  IotCommandState stateFor(IotCommandTarget target) => _states[target] ?? const IotCommandState();
  bool isPending(IotCommandTarget target) {
    final state = stateFor(target);
    return _submitting.contains(target) || (state.status.name == 'pending' && !state.isObjectivelyExpired(DateTime.now()));
  }
  String? errorFor(IotCommandTarget target) => _states[target]?.errorCode;

  void start() {
    for (final target in IotCommandTarget.values) {
      _watch(target);
    }
  }

  Future<void> submit(IotCommandTarget target, Object desiredValue) async {
    _validate(target, desiredValue);
    _watch(target);
    if (isPending(target)) throw StateError('A command for ${target.path} is still pending.');
    _submitting.add(target); notifyListeners();
    try {
      await _database.ref('deviceCommands/$deviceId/${target.path}').set({
        'commandId': _uuid(), 'desiredValue': desiredValue,
        'issuedAt': ServerValue.timestamp, 'ttlMs': ttlMs, 'status': 'pending',
      });
    } finally { _submitting.remove(target); notifyListeners(); }
  }

  void _watch(IotCommandTarget target) {
    if (_subscriptions.containsKey(target)) return;
    _subscriptions[target] = _database.ref('deviceCommands/$deviceId/${target.path}').onValue.listen((event) {
      _states[target] = IotCommandState.fromRealtimeValue(event.snapshot.value);
      notifyListeners();
    });
  }
  void _validate(IotCommandTarget target, Object value) {
    if (target.acceptsBoolean && value is! bool) throw ArgumentError.value(value, 'desiredValue', 'A boolean is required.');
    if (!target.acceptsBoolean && value is! String) throw ArgumentError.value(value, 'desiredValue', 'A mode string is required.');
    if (!target.acceptsBoolean && value != 'automatic' && value != 'manual') throw ArgumentError.value(value, 'desiredValue', 'Use automatic or manual.');
  }
  String _uuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
  @override void dispose() { for (final subscription in _subscriptions.values) { subscription.cancel(); } super.dispose(); }
}

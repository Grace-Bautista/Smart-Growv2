import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/sensor_data.dart';
import 'sensor_service.dart';

enum EspConnectionState { unknown, offline, online }

/// Shared ESP32 connection-state service.
///
/// This is the single source of truth for the ESP32 Online/Offline
/// state used by:
///
/// - Dashboard
/// - Settings
/// - Notifications
///
/// ESP32 currently sends a heartbeat every 5 seconds.
///
/// A fresh heartbeat marks the ESP32 Online immediately.
/// If no new heartbeat arrives for 11 seconds, the shared
/// connection state becomes Offline.
///
/// This service does NOT control sensor readings or commands.
class Esp32Service {
  Esp32Service._();

  static final Esp32Service instance = Esp32Service._();

  final SensorService _sensorService = SensorService.instance;

  // ============================================================
  // SHARED CONNECTION STATE
  // ============================================================

  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(false);

  /// Includes the initial synchronization state so notification consumers can
  /// distinguish "not evaluated yet" from a genuine Offline state.
  final ValueNotifier<EspConnectionState> connectionState =
      ValueNotifier<EspConnectionState>(EspConnectionState.unknown);

  StreamSubscription<SensorData>? _subscription;

  Timer? _offlineTimer;

  DateTime? _lastHeartbeatSeen;

  bool _started = false;

  // ESP heartbeat = every 5 seconds.
  // Allow roughly two missed heartbeats before showing Offline.
  static const Duration offlineTimeout = Duration(seconds: 11);

  // ============================================================
  // START
  // ============================================================

  void start() {
    if (_started) {
      return;
    }

    _started = true;

    _subscription = _sensorService.watchLiveData().listen(
      _handleLiveData,
      onError: (Object error) {
        debugPrint(
          'Esp32Service RTDB connection error: $error',
        );
      },
    );
  }

  // ============================================================
  // LIVE DATA
  // ============================================================

  void _handleLiveData(SensorData data) {
    final heartbeat = data.lastHeartbeat;

    if (heartbeat == null) {
      return;
    }

    // RTDB may update sensors/components between heartbeats.
    //
    // Only a genuinely NEW heartbeat is allowed to reset
    // the offline watchdog.
    if (_lastHeartbeatSeen == heartbeat) {
      return;
    }

    _lastHeartbeatSeen = heartbeat;

    // New heartbeat received.
    _offlineTimer?.cancel();
    _offlineTimer = null;

    final heartbeatAge =
        DateTime.now().difference(heartbeat);

    // ----------------------------------------------------------
    // ALREADY STALE
    // ----------------------------------------------------------

    if (!heartbeatAge.isNegative &&
        heartbeatAge >= offlineTimeout) {
      _setConnectionState(EspConnectionState.offline);
      return;
    }

    // ----------------------------------------------------------
    // FRESH HEARTBEAT
    // ----------------------------------------------------------

    _setConnectionState(EspConnectionState.online);

    // Account for the heartbeat already being a little old when
    // Flutter receives it.
    final remaining = heartbeatAge.isNegative
        ? offlineTimeout
        : offlineTimeout - heartbeatAge;

    final watchedHeartbeat = heartbeat;

    // ----------------------------------------------------------
    // OFFLINE WATCHDOG
    // ----------------------------------------------------------

    _offlineTimer = Timer(
      remaining,
      () {
        // If another heartbeat arrived, this timer belongs
        // to an older heartbeat and must be ignored.
        if (_lastHeartbeatSeen != watchedHeartbeat) {
          return;
        }

        _setConnectionState(EspConnectionState.offline);
      },
    );
  }

  // ============================================================
  // STATE CHANGE
  // ============================================================

  void _setConnectionState(EspConnectionState value) {
    // Do not emit duplicate states.
    if (connectionState.value == value) {
      return;
    }

    final online = value == EspConnectionState.online;
    if (isOnline.value != online) {
      isOnline.value = online;
    }

    // Publish the complete state after the boolean view is synchronized so
    // listeners always observe a consistent snapshot.
    connectionState.value = value;

    debugPrint(
      'ESP32 connection: ${value.name.toUpperCase()}',
    );
  }

  // ============================================================
  // STOP
  // ============================================================

  Future<void> stop() async {
    _offlineTimer?.cancel();
    _offlineTimer = null;

    await _subscription?.cancel();
    _subscription = null;

    _lastHeartbeatSeen = null;

    _setConnectionState(EspConnectionState.unknown);

    _started = false;
  }
}

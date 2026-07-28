import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class Esp32Snapshot {
  const Esp32Snapshot({
    required this.connected,
    required this.powerOn,
    required this.fanOn,
    required this.fanMode,
    required this.pumpOn,
    required this.uvOn,
    required this.waterPresent,
    required this.sensorOnline,
    this.temperature,
    this.humidity,
    this.co2,
  });

  final bool connected;
  final bool powerOn;
  final bool fanOn;
  final String fanMode;
  final bool pumpOn;
  final bool uvOn;
  final bool waterPresent;
  final bool sensorOnline;
  final double? temperature;
  final double? humidity;
  final int? co2;

  bool get humidifierOn => pumpOn;

  bool get hasSensorData =>
      temperature != null || humidity != null || co2 != null;

  factory Esp32Snapshot.offline() {
    return const Esp32Snapshot(
      connected: false,
      powerOn: false,
      fanOn: false,
      fanMode: 'manual',
      pumpOn: false,
      uvOn: false,
      waterPresent: false,
      sensorOnline: false,
    );
  }

  factory Esp32Snapshot.fromJson(Map<String, dynamic> json) {
    return Esp32Snapshot(
      connected: true,
      powerOn: _readBool(json['power']),
      fanOn: _readBool(json['fan']),
      fanMode: (json['fanMode'] ?? 'manual').toString().toLowerCase(),
      pumpOn: _readBool(json['pump'] ?? json['humidifier']),
      uvOn: _readBool(json['uv']),
      waterPresent: _readBool(json['water']),
      sensorOnline: _readBool(json['sensorOnline']),
      temperature: _readDouble(json['temperature'] ?? json['temp']),
      humidity: _readDouble(json['humidity']),
      co2: _readInt(json['co2']),
    );
  }
}

class Esp32Service {
  static const String baseUrl = 'http://192.168.4.1';
  static const Duration _timeout = Duration(seconds: 2);

  static Future<Esp32Snapshot> readSnapshot() async {
    try {
      final json = await _getJson('/status');
      return Esp32Snapshot.fromJson(json);
    } catch (_) {
      return Esp32Snapshot.offline();
    }
  }

  static Future<double> readTemperature() async {
    final json = await _getJson('/temperature');
    final value = _readDouble(json['temperature']);
    if (value == null) {
      throw Exception('Temperature unavailable');
    }
    return value;
  }

  static Future<double> readHumidity() async {
    final json = await _getJson('/humidity');
    final value = _readDouble(json['humidity']);
    if (value == null) {
      throw Exception('Humidity unavailable');
    }
    return value;
  }

  static Future<int> readCO2() async {
    final json = await _getJson('/co2');
    final value = _readInt(json['co2']);
    if (value == null) {
      throw Exception('CO2 unavailable');
    }
    return value;
  }

  static Future<bool> isWaterPresent() async {
    final json = await _getJson('/water');
    return _readBool(json['water']);
  }

  static Future<bool> fanOn() => _sendToggle('/fan/on');

  static Future<bool> fanOff() => _sendToggle('/fan/off');

  static Future<bool> getFanStatus() async {
    final json = await _getJson('/fan/status');
    return _readBool(json['fan']);
  }

  static Future<String> getFanMode() async {
    final json = await _getJson('/fan/status');
    return (json['mode'] ?? 'manual').toString().toLowerCase();
  }

  static Future<bool> setFanModeAuto() => _sendToggle('/fan/mode/auto');

  static Future<bool> setFanModeManual() => _sendToggle('/fan/mode/manual');

  static Future<bool> humidifierOn() => _sendToggle('/humidifier/on');

  static Future<bool> humidifierOff() => _sendToggle('/humidifier/off');

  static Future<bool> getHumidifierStatus() async {
    final json = await _getJson('/humidifier/status');
    return _readBool(json['humidifier']);
  }

  static Future<bool> uvOn() => _sendToggle('/uv/on');

  static Future<bool> uvOff() => _sendToggle('/uv/off');

  static Future<bool> getUvStatus() async {
    final json = await _getJson('/uv/status');
    return _readBool(json['uv']);
  }

  static Future<bool> isConnected() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/ping'))
          .timeout(const Duration(seconds: 1));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> powerRailOn() => _sendToggle('/power/on');

  static Future<bool> powerRailOff() => _sendToggle('/power/off');

  static Future<bool> getPowerStatus() async {
    final json = await _getJson('/power/status');
    return _readBool(json['power']);
  }

  static Future<Map<String, dynamic>> _getJson(String path) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$path'))
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw HttpException(
          'ESP32 request failed (${response.statusCode})',
          uri: Uri.parse('$baseUrl$path'),
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('ESP32 response is not a JSON object');
      }

      return decoded;
    } on TimeoutException {
      throw Exception('ESP32 request timeout for $path');
    } on SocketException {
      throw Exception('ESP32 offline');
    } on FormatException catch (_) {
      throw Exception('Invalid response from $path');
    }
  }

  static Future<bool> _sendToggle(String path) async {
    try {
      await _getJson(path);
      return true;
    } catch (_) {
      return false;
    }
  }
}

bool _readBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.toLowerCase();
    return normalized == '1' ||
        normalized == 'true' ||
        normalized == 'on' ||
        normalized == 'auto';
  }
  return false;
}

double? _readDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? _readInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

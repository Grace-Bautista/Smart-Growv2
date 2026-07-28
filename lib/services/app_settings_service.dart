import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppFontSettings {
  const AppFontSettings({
    required this.headerFontSize,
    required this.bodyFontSize,
  });

  final double headerFontSize;
  final double bodyFontSize;

  AppFontSettings copyWith({
    double? headerFontSize,
    double? bodyFontSize,
  }) {
    return AppFontSettings(
      headerFontSize: headerFontSize ?? this.headerFontSize,
      bodyFontSize: bodyFontSize ?? this.bodyFontSize,
    );
  }
}

class AppSettingsService {
  static const _headerKey = 'settings.headerFontSize';
  static const _bodyKey = 'settings.bodyFontSize';

  static final ValueNotifier<AppFontSettings> settings =
      ValueNotifier(const AppFontSettings(headerFontSize: 18, bodyFontSize: 14));

  static AppFontSettings get current => settings.value;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    settings.value = AppFontSettings(
      headerFontSize: prefs.getDouble(_headerKey) ?? 18,
      bodyFontSize: prefs.getDouble(_bodyKey) ?? 14,
    );
  }

  static Future<void> save(AppFontSettings next) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_headerKey, next.headerFontSize);
    await prefs.setDouble(_bodyKey, next.bodyFontSize);
    settings.value = next;
  }

  
}

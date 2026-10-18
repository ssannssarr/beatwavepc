import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beatwave/core/constants/setting_keys.dart';
import 'package:beatwave/blocs/settings_cubit/cubit/settings_cubit.dart';
import 'package:beatwave/core/theme/app_theme.dart';
import 'package:beatwave/core/scroll/lenis_smooth_scroll.dart';

void main() {
  group('8D Audio Settings & State', () {
    test('SettingKeys contains 8D audio keys', () {
      expect(SettingKeys.eightDEnabled, equals('eightDEnabled'));
      expect(SettingKeys.eightDSpeed, equals('eightDSpeed'));
    });

    test('SettingsInitial initializes with 8D audio disabled and default 0.10 speed', () {
      final initial = SettingsInitial();
      expect(initial.eightDEnabled, isFalse);
      expect(initial.eightDSpeed, equals(0.10));
    });

    test('SettingsState copyWith updates eightDEnabled and eightDSpeed correctly', () {
      final initial = SettingsInitial();
      final updated = initial.copyWith(eightDEnabled: true, eightDSpeed: 0.14);
      expect(updated.eightDEnabled, isTrue);
      expect(updated.eightDSpeed, equals(0.14));
      expect(initial.eightDEnabled, isFalse);
    });
  });

  group('Dark OLED Theme', () {
    test('SettingKeys contains darkOledTheme', () {
      expect(SettingKeys.darkOledTheme, equals('dark_oled_theme'));
    });

    test('Dark OLED is enabled by default out of the box in SettingsInitial', () {
      final initial = SettingsInitial();
      expect(initial.darkOledTheme, isTrue);
    });

    test('SettingsState copyWith updates darkOledTheme', () {
      final initial = SettingsInitial();
      final updated = initial.copyWith(darkOledTheme: false);
      expect(updated.darkOledTheme, isFalse);
      expect(initial.darkOledTheme, isTrue);
    });

    test('AppTheme default is pure black Color(0xFF000000)', () {
      expect(AppTheme.themeColor, equals(const Color(0xFF000000)));
      final oledTheme = AppTheme.getThemeData(oled: true);
      expect(oledTheme.scaffoldBackgroundColor, equals(const Color(0xFF000000)));

      final classicTheme = AppTheme.getThemeData(oled: false);
      expect(classicTheme.scaffoldBackgroundColor, equals(const Color(0xFF0A040C)));
    });
  });

  group('Lenis Smooth Scroll', () {
    test('LenisScrollBehavior instantiates with fast bouncing physics and drag devices', () {
      const behavior = LenisScrollBehavior();
      expect(behavior.dragDevices.contains(PointerDeviceKind.mouse), isTrue);
      expect(behavior.dragDevices.contains(PointerDeviceKind.touch), isTrue);

      const physics = LenisScrollPhysics();
      expect(physics.decelerationRate, equals(ScrollDecelerationRate.fast));
    });
  });
}

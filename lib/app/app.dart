import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:hire_craft/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'router.dart';

class ThemeSettings {
  const ThemeSettings({
    required this.themeMode,
    required this.useSystemMonet,
    required this.customSeedColorValue,
  });

  final ThemeMode themeMode;
  final bool useSystemMonet;
  final int customSeedColorValue;

  Color get customSeedColor => Color(customSeedColorValue);

  ThemeSettings copyWith({
    ThemeMode? themeMode,
    bool? useSystemMonet,
    int? customSeedColorValue,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      useSystemMonet: useSystemMonet ?? this.useSystemMonet,
      customSeedColorValue: customSeedColorValue ?? this.customSeedColorValue,
    );
  }
}

final themeSettingsProvider =
    AsyncNotifierProvider<ThemeSettingsNotifier, ThemeSettings>(
      ThemeSettingsNotifier.new,
    );

class ThemeSettingsNotifier extends AsyncNotifier<ThemeSettings> {
  static const _themeModeKey = 'theme_mode';
  static const _monetKey = 'use_system_monet';
  static const _customSeedColorKey = 'custom_seed_color';

  @override
  Future<ThemeSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final storedTheme = prefs.getString(_themeModeKey);
    final storedMonet = prefs.getBool(_monetKey);
    final storedCustomColor = prefs.getInt(_customSeedColorKey);

    return ThemeSettings(
      themeMode: _themeModeFromString(storedTheme),
      useSystemMonet: storedMonet ?? true,
      customSeedColorValue: storedCustomColor ?? AppTheme.seedColor.toARGB32(),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final current =
        state.asData?.value ??
        ThemeSettings(
          themeMode: ThemeMode.system,
          useSystemMonet: true,
          customSeedColorValue: AppTheme.seedColor.toARGB32(),
        );
    final next = current.copyWith(themeMode: mode);
    state = AsyncData(next);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _themeModeToString(mode));
  }

  Future<void> setUseSystemMonet(bool enabled) async {
    final current =
        state.asData?.value ??
        ThemeSettings(
          themeMode: ThemeMode.system,
          useSystemMonet: true,
          customSeedColorValue: AppTheme.seedColor.toARGB32(),
        );
    final next = current.copyWith(useSystemMonet: enabled);
    state = AsyncData(next);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_monetKey, enabled);
  }

  Future<void> setCustomSeedColor(Color color) async {
    final current =
        state.asData?.value ??
        ThemeSettings(
          themeMode: ThemeMode.system,
          useSystemMonet: true,
          customSeedColorValue: AppTheme.seedColor.toARGB32(),
        );
    final next = current.copyWith(customSeedColorValue: color.toARGB32());
    state = AsyncData(next);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_customSeedColorKey, color.toARGB32());
  }

  ThemeMode _themeModeFromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

class HireCraftApp extends StatelessWidget {
  const HireCraftApp({super.key, this.overrides = const []});

  final List overrides;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(overrides: overrides.cast(), child: const _AppView());
  }
}

class _AppView extends ConsumerWidget {
  const _AppView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(themeSettingsProvider).asData?.value ??
        ThemeSettings(
          themeMode: ThemeMode.system,
          useSystemMonet: true,
          customSeedColorValue: AppTheme.seedColor.toARGB32(),
        );
    final appRouter = ref.watch(appRouterProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final lightScheme = settings.useSystemMonet
            ? lightDynamic
            : ColorScheme.fromSeed(
                seedColor: settings.customSeedColor,
                brightness: Brightness.light,
              );
        final darkScheme = settings.useSystemMonet
            ? darkDynamic
            : ColorScheme.fromSeed(
                seedColor: settings.customSeedColor,
                brightness: Brightness.dark,
              );

        return MaterialApp.router(
          title: 'Hire Craft',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: AppTheme.lightTheme(lightScheme),
          darkTheme: AppTheme.darkTheme(darkScheme),
          routerConfig: appRouter,
        );
      },
    );
  }
}

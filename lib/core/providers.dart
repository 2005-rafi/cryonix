import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'i_database.dart';
import 'startup_notifier.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Feature code should depend on [IDatabase]; use [appDatabaseProvider] only
/// when Drift-specific APIs are required.
final databaseProvider = Provider<IDatabase>((ref) {
  return ref.watch(appDatabaseProvider);
});

final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

final startupProvider = StateNotifierProvider<StartupNotifier, StartupState>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return StartupNotifier(db);
});

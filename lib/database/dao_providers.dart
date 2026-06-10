import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i_database.dart';
import '../core/providers.dart';
import 'app_database.dart';

/// DAO-layer providers for Drift.
///
/// Uses manual [Provider] declarations because `riverpod_generator` shares a
/// conflicting `build` dependency with `drift_dev` in this project.
final driftAppDatabaseProvider = Provider<AppDatabase>(
  (ref) => ref.watch(appDatabaseProvider),
);

final iDatabaseProvider = Provider<IDatabase>(
  (ref) => ref.watch(databaseProvider),
);

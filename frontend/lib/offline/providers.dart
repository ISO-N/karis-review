import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database/app_database.dart';
import 'offline_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final offlineRepositoryProvider = Provider<OfflineRepository>((ref) {
  return OfflineRepository(ref.watch(appDatabaseProvider));
});

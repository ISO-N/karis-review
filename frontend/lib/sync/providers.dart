import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../offline/providers.dart';
import 'repositories/sync_repository.dart';
import 'sync_service.dart';

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.watch(syncRepositoryProvider),
    ref.watch(offlineRepositoryProvider),
  );
});

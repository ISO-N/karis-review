import '../auth/models/login_response.dart';
import '../offline/offline_repository.dart';
import '../review/models/review_card.dart';
import 'repositories/sync_repository.dart';

class SyncOutcome {
  final int synced;
  final int conflicts;
  final int missing;

  const SyncOutcome({this.synced = 0, this.conflicts = 0, this.missing = 0});
}

class SyncService {
  final SyncRepository _repository;
  final OfflineRepository _offline;

  SyncService(this._repository, this._offline);

  Future<void> bootstrap({required String userId}) async {
    final data = await _repository.fetchBootstrap();
    await _saveBootstrap(data, userId);
  }

  Future<UserInfo> bootstrapFromServer() async {
    final data = await _repository.fetchBootstrap();
    final user = UserInfo.fromJson(data['user'] as Map<String, dynamic>);
    await _saveBootstrap(data, user.id);
    return user;
  }

  Future<void> _saveBootstrap(Map<String, dynamic> data, String userId) async {
    final user = data['user'] as Map<String, dynamic>;
    await _offline.saveBootstrap(
      userId: userId,
      email: user['email'] as String? ?? '',
      refreshTime: user['refresh_time'] as String? ?? '04:00:00',
      serverTime: DateTime.parse(data['server_time'] as String),
      decks: (data['decks'] as List? ?? const []).cast<Map<String, dynamic>>(),
      reviewLogs: (data['review_logs'] as List? ?? const [])
          .cast<Map<String, dynamic>>(),
    );
  }

  Future<SyncOutcome> syncPending({required String userId}) async {
    final pending = await _offline.getPendingRatings(userId);
    if (pending.isEmpty) return const SyncOutcome();

    final items = pending.map((log) {
      return {
        'client_request_id': log.clientRequestId ?? log.id,
        'card_id': log.cardId,
        'rating': log.rating,
        'rated_at': log.reviewedAt.toUtc().toIso8601String(),
        'review_version': log.reviewVersion.toInt(),
      };
    }).toList();
    final cardByClientId = {
      for (final log in pending) log.clientRequestId ?? log.id: log.cardId,
    };

    final data = await _repository.syncRatings(items);
    final results = (data['items'] as List? ?? const [])
        .cast<Map<String, dynamic>>();

    var synced = 0;
    var conflicts = 0;
    var missing = 0;

    for (final result in results) {
      final clientId = result['client_request_id'] as String;
      final status = result['status'] as String? ?? '';
      switch (status) {
        case 'SYNCED':
        case 'ALREADY_SYNCED':
          await _offline.markSynced(userId, clientId);
          synced += 1;
        case 'CONFLICT':
          await _offline.markDiscarded(userId, clientId);
          final currentCard = result['current_card'];
          if (currentCard is Map<String, dynamic>) {
            await _offline.updateCardFromServer(
              userId,
              ReviewCard.fromJson(currentCard),
            );
          }
          conflicts += 1;
        case 'CARD_NOT_FOUND':
          await _offline.markDiscarded(userId, clientId);
          final cardId = cardByClientId[clientId];
          if (cardId != null) {
            await _offline.removeCard(userId, cardId);
          }
          missing += 1;
      }
    }

    return SyncOutcome(synced: synced, conflicts: conflicts, missing: missing);
  }

  Future<void> forceServerAuthoritative({required String userId}) async {
    await _offline.discardAllPending(userId);
    await bootstrap(userId: userId);
  }
}

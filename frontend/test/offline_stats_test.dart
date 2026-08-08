import 'package:flutter_test/flutter_test.dart';
import 'package:karisreview/offline/database/app_database.dart';
import 'package:karisreview/offline/offline_stats.dart';

/// offline_stats 纯计算单测（架构评审 F5）：
/// 统计口径/分布/去重此前混在 OfflineRepository 内只能经 Drift 间接测，
/// 下沉为纯函数后接口即测试面。
void main() {
  LocalReviewLog log({
    required String rating,
    required bool isNewCard,
    String? learningOrigin,
    DateTime? reviewedAt,
    String? clientRequestId,
    String syncStatus = 'SYNCED',
  }) {
    return LocalReviewLog(
      id: clientRequestId ?? 'log-1',
      userId: 'user-1',
      cardId: 'card-1',
      rating: rating,
      stageBefore: 0,
      stageAfter: 1,
      isNewCard: isNewCard,
      learningOrigin: learningOrigin,
      reviewedAt: reviewedAt ?? DateTime.utc(2025, 8, 2, 12),
      clientRequestId: clientRequestId,
      reviewVersion: BigInt.zero,
      syncStatus: syncStatus,
    );
  }

  group('stageDistribution', () {
    test('按 stage 累加，9 位列表', () {
      expect(stageDistribution([0, 1, 1, 8]), [1, 2, 0, 0, 0, 0, 0, 0, 1]);
    });

    test('越界 stage 忽略', () {
      expect(stageDistribution([-1, 9, 3]), [0, 0, 0, 1, 0, 0, 0, 0, 0]);
    });
  });

  group('今日复习/今日新学口径（与后端 ReviewLogQueryPredicates 一致）', () {
    test('reviewed：非新卡且非 NEW 来源 → 计入', () {
      expect(isReviewedTodayLog(log(rating: 'FAMILIAR', isNewCard: false)), isTrue);
      expect(
        isReviewedTodayLog(
          log(rating: 'FORGET', isNewCard: false, learningOrigin: 'REVIEW'),
        ),
        isTrue,
      );
    });

    test('reviewed：学新阶段重学（origin=NEW）→ 不计入', () {
      expect(
        isReviewedTodayLog(
          log(rating: 'FORGET', isNewCard: false, learningOrigin: 'NEW'),
        ),
        isFalse,
      );
    });

    test('reviewed：新卡评分 → 不计入', () {
      expect(isReviewedTodayLog(log(rating: 'FAMILIAR', isNewCard: true)), isFalse);
    });

    test('learned：新卡且 FAMILIAR → 计入；其他不计', () {
      expect(isLearnedTodayLog(log(rating: 'FAMILIAR', isNewCard: true)), isTrue);
      expect(isLearnedTodayLog(log(rating: 'FORGET', isNewCard: true)), isFalse);
      expect(isLearnedTodayLog(log(rating: 'FAMILIAR', isNewCard: false)), isFalse);
    });
  });

  group('dedupeReviewLogs', () {
    test('丢弃 DISCARDED', () {
      final rows = [
        log(rating: 'FAMILIAR', isNewCard: true, syncStatus: 'DISCARDED'),
        log(rating: 'FAMILIAR', isNewCard: true),
      ];
      expect(dedupeReviewLogs(rows), hasLength(1));
    });

    test('同 clientRequestId 服务端来源替换本地镜像', () {
      // 本地镜像 id == clientRequestId；服务端来源 id 不同。
      final rows = <LocalReviewLog>[
        LocalReviewLog(
          id: 'same-id',
          userId: 'user-1',
          cardId: 'card-1',
          rating: 'FAMILIAR',
          stageBefore: 0,
          stageAfter: 1,
          isNewCard: true,
          reviewedAt: DateTime.utc(2025, 8, 2, 12),
          clientRequestId: 'same-id',
          reviewVersion: BigInt.zero,
          syncStatus: 'SYNCED',
        ),
        LocalReviewLog(
          id: 'server-id',
          userId: 'user-1',
          cardId: 'card-1',
          rating: 'FAMILIAR',
          stageBefore: 0,
          stageAfter: 1,
          isNewCard: true,
          reviewedAt: DateTime.utc(2025, 8, 2, 12),
          clientRequestId: 'same-id',
          reviewVersion: BigInt.zero,
          syncStatus: 'SYNCED',
        ),
      ];
      final result = dedupeReviewLogs(rows);
      expect(result, hasLength(1));
      expect(result.single.id, 'server-id');
    });
  });
}

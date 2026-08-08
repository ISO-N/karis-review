import '../shared/utils/date_utils.dart';
import '../shared/scheduling/rating.dart';
import 'database/app_database.dart';
import 'local_scheduling_engine.dart';

/// 离线统计纯计算（架构评审 F5，2026-08）。
///
/// 统计口径、阶段分布、日志去重此前混在 OfflineRepository（1078 行）内部，
/// 统计方法需经 repository + Drift 才可测；本模块下沉为无状态纯函数，
/// 接口即测试面（offline_stats_test 直接断言），repository 回归数据访问。
///
/// 口径与后端 ReviewLogQueryPredicates / CardQueryPredicates 一致，
/// 改口径必须两端同步。

/// 阶段分布：9 位列表按 stage 累加，越界忽略（对应后端 distributionFromRows）。
List<int> stageDistribution(Iterable<int> stages) {
  final result = List<int>.filled(9, 0);
  for (final stage in stages) {
    if (stage >= 0 && stage < 9) result[stage] += 1;
  }
  return result;
}

/// 日志是否属于「今日复习」口径（与后端 REVIEWED_TODAY 一致）：
/// 非新卡评分且非「学新阶段重学」评分（origin <> 'NEW'）——只统计
/// 到期卡复习 + 复习阶段重学，学新阶段的重学评分不计入。
bool isReviewedTodayLog(LocalReviewLog log) =>
    !log.isNewCard &&
    (log.learningOrigin == null || log.learningOrigin != 'NEW');

/// 日志是否属于「今日新学」口径（与后端 LEARNED_TODAY 一致）：新卡且 FAMILIAR。
bool isLearnedTodayLog(LocalReviewLog log) =>
    log.isNewCard && log.rating == Rating.familiar;

/// 业务日判定：评分时间按刷新点折算后是否落在指定业务日（DateUtils.calculateToday 口径）。
bool isOnRefreshDay(DateTime reviewedAt, String refreshTime, String day) {
  final refreshDay = LocalSchedulingEngine.calculateToday(
    reviewedAt,
    refreshTime,
  );
  return AppDateUtils.formatDate(refreshDay) == day;
}

/// 本地镜像判定：clientRequestId == id 的日志是本地生成后同步的服务端镜像
/// （与原始本地行同键），去重时服务端来源优先于本地镜像。
bool isLocalMirror(LocalReviewLog log) =>
    log.clientRequestId != null && log.clientRequestId == log.id;

/// 日志事件键：同一事件（同卡、同评分、同前后 stage、同秒、同新卡标记）
/// 的服务端来源与本地镜像共享该键，用于第二轮去重。
String reviewLogEventKey(LocalReviewLog log) {
  final reviewedAt = log.reviewedAt.toUtc();
  final reviewedSecond = DateTime.utc(
    reviewedAt.year,
    reviewedAt.month,
    reviewedAt.day,
    reviewedAt.hour,
    reviewedAt.minute,
    reviewedAt.second,
  ).microsecondsSinceEpoch;
  return [
    log.cardId,
    log.rating,
    log.stageBefore,
    log.stageAfter,
    reviewedSecond,
    log.isNewCard,
  ].join('|');
}

/// 日志去重（同步镜像去重，原 OfflineRepository._getLogs 内的两轮逻辑）：
/// 1) 丢弃 DISCARDED；按 clientRequestId 去重，服务端来源替换本地镜像；
/// 2) 按事件键去重，同事件的服务端来源替换本地镜像。
/// 返回保序的去重后日志列表。
List<LocalReviewLog> dedupeReviewLogs(List<LocalReviewLog> rows) {
  final clientDeduped = <LocalReviewLog>[];
  final byClientId = <String, LocalReviewLog>{};
  for (final log in rows) {
    if (log.syncStatus == 'DISCARDED') continue;
    final clientId = log.clientRequestId;
    if (clientId != null) {
      final existing = byClientId[clientId];
      if (existing != null) {
        if (isLocalMirror(log) && !isLocalMirror(existing)) continue;
        if (!isLocalMirror(log) && isLocalMirror(existing)) {
          final index = clientDeduped.indexOf(existing);
          clientDeduped[index] = log;
          byClientId[clientId] = log;
        }
        continue;
      }
      byClientId[clientId] = log;
    }
    clientDeduped.add(log);
  }

  final result = <LocalReviewLog>[];
  final byEvent = <String, LocalReviewLog>{};
  for (final log in clientDeduped) {
    final eventKey = reviewLogEventKey(log);
    final existing = byEvent[eventKey];
    if (existing != null) {
      if (isLocalMirror(log) && !isLocalMirror(existing)) continue;
      if (!isLocalMirror(log) && isLocalMirror(existing)) {
        final index = result.indexOf(existing);
        result[index] = log;
        byEvent[eventKey] = log;
      }
      continue;
    }
    byEvent[eventKey] = log;
    result.add(log);
  }
  return result;
}

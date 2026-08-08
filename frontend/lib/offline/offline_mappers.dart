library;

import '../card/models/card.dart';
import '../review/models/review_card.dart';
import 'database/app_database.dart';

/// 卡片映射单一实现（架构评审 F5，2026-08）。
///
/// LocalCard → FlashCard/ReviewCard 与 FlashCard → ReviewCard 此前分别
/// 写在 OfflineRepository 与 ReviewNotifier 内，字段逐一重复，ReviewCard
/// 增字段需改两处；本模块收敛三种映射，模型层变更一处生效。

/// 本地卡 → 复习卡（离线队列构建出口）。
ReviewCard reviewCardFromLocal(LocalCard card) {
  return ReviewCard(
    id: card.id,
    deckId: card.deckId,
    front: card.front,
    back: card.back,
    stage: card.stage,
    learningMode: card.learningMode,
    consecutiveFamiliar: card.consecutiveFamiliar,
    learningStep: card.learningStep,
    reentryStage: card.reentryStage,
    nextReviewDate: card.nextReviewDate,
    reviewVersion: card.reviewVersion.toInt(),
    learningOrigin: card.learningOrigin,
  );
}

/// 本地卡 → 卡片列表项（含 due 标记）。
FlashCard flashCardFromLocal(LocalCard card, {required String today}) {
  return FlashCard(
    id: card.id,
    deckId: card.deckId,
    front: card.front,
    back: card.back,
    stage: card.stage,
    nextReviewDate: card.nextReviewDate,
    learningMode: card.learningMode,
    consecutiveFamiliar: card.consecutiveFamiliar,
    learningStep: card.learningStep,
    reentryStage: card.reentryStage,
    due:
        card.nextReviewDate != null &&
        card.nextReviewDate!.compareTo(today) <= 0,
    createdAt: card.createdAt?.toIso8601String() ?? '',
    reviewVersion: card.reviewVersion.toInt(),
    learningOrigin: card.learningOrigin,
  );
}

/// 会话卡 → 复习卡（与 [reviewCardFromLocal] 同构，输入为在线 FlashCard）。
ReviewCard reviewCardFromFlash(FlashCard card) {
  return ReviewCard(
    id: card.id,
    deckId: card.deckId,
    front: card.front,
    back: card.back,
    stage: card.stage,
    learningMode: card.learningMode,
    consecutiveFamiliar: card.consecutiveFamiliar,
    learningStep: card.learningStep,
    reentryStage: card.reentryStage,
    nextReviewDate: card.nextReviewDate,
    reviewVersion: card.reviewVersion,
    learningOrigin: card.learningOrigin,
  );
}

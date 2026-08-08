import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:karisreview/card/models/card.dart';
import 'package:karisreview/offline/local_scheduling_engine.dart';

/// 排期公式跨语言等价性测试（架构评审 A1，2026-08-08）。
///
/// 读取 docs/design/scheduling-vectors.json（语言无关单一事实源），对每条向量
/// 调用 LocalSchedulingEngine 断言结果。后端 SchedulingVectorsTest 读同一份
/// 文件——改公式必须改向量文件且两端测试同绿。
///
/// 向量文件相对路径：flutter test 工作目录为 frontend/，文件位于仓库根 docs/design/。
void main() {
  final engine = LocalSchedulingEngine();
  final now = DateTime.utc(2025, 8, 2, 12);

  FlashCard cardFromInput(Map<String, dynamic> input, {String? nextReviewDate}) {
    final reentry = input['reentryStage'];
    return FlashCard(
      id: 'vector-card',
      deckId: 'deck-1',
      front: '正面',
      back: '反面',
      stage: input['stage'] as int,
      nextReviewDate: nextReviewDate,
      learningMode: input['learningMode'] as bool,
      consecutiveFamiliar: input['consecutiveFamiliar'] as int,
      learningStep: input['learningStep'] as int,
      reentryStage: reentry == null ? null : reentry as int,
      learningOrigin: input['learningOriginInput'] as String?,
      reviewVersion: 0,
    );
  }

  test('all rating vectors match local engine', () async {
    final file = File('../docs/design/scheduling-vectors.json');
    expect(file.existsSync(), isTrue,
        reason: '找不到 scheduling-vectors.json，请确认文件位于 docs/design/ 下');
    final root = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final vectors = root['vectors'] as List<dynamic>;

    var ratingCases = 0;
    var effectiveCases = 0;
    for (final v in vectors) {
      final id = v['id'] as String;
      final input = v['input'] as Map<String, dynamic>;
      final expected = v['expected'] as Map<String, dynamic>;
      final rating = input['rating'] as String;

      if (rating == 'NONE') {
        final stage = input['stage'] as int;
        final overdueDays = input['overdueDays'] as int;
        final actual = LocalSchedulingEngine.calculateEffectiveStage(stage, overdueDays);
        expect(actual, expected['effectiveStage'], reason: 'effectiveStage 向量 $id');
        effectiveCases++;
        continue;
      }

      final overdueDays = input['overdueDays'] as int;
      // VAGUE 逾期天数由 nextReviewDate 推导：nextReviewDate = today - overdueDays
      final nextReviewDate = overdueDays == 0
          ? null
          : DateTime(2025, 8, 2).subtract(Duration(days: overdueDays)).toIso8601String().substring(0, 10);
      final card = cardFromInput(input, nextReviewDate: nextReviewDate);
      final outcome = engine.rate(card, rating, nowUtc: now, refreshTime: '04:00:00');

      expect(outcome.card.stage, expected['stageAfter'], reason: '向量 $id stageAfter');
      expect(outcome.card.learningMode, expected['learningMode'], reason: '向量 $id learningMode');
      expect(outcome.card.consecutiveFamiliar, expected['consecutiveFamiliar'], reason: '向量 $id consecutiveFamiliar');
      expect(outcome.result.nextIntervalDays, expected['nextIntervalDays'], reason: '向量 $id nextIntervalDays');
      expect(outcome.card.learningOrigin, expected['learningOrigin'], reason: '向量 $id learningOrigin');

      final wantReentry = expected['reentryStageAfter'];
      if (wantReentry != null) {
        expect(outcome.card.reentryStage, wantReentry, reason: '向量 $id reentryStage');
      }
      ratingCases++;
    }
    expect(ratingCases, greaterThanOrEqualTo(15), reason: '评分向量用例数不足');
    expect(effectiveCases, greaterThanOrEqualTo(8), reason: 'effectiveStage 向量用例数不足');
  });
}

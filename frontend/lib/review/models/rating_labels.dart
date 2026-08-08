/// 复习页评分展示/快捷键纯函数（架构评审 D1，2026-08-08）。
///
/// 评分→中文标签、键盘数字→评分、间隔文案三份逻辑此前在 review_page
/// 的 _rate()/announceMessage、_StatusChip._specFor、快捷键映射中逐字符
/// 重复；本文件收敛为纯函数，接口即测试面。间隔文案委托 KarisTheme.intervalLabel
/// 单一实现（0 天 → 「重学」，1 天 → 「1 天」，N 天 → 「N 天」）。
library;

import 'package:flutter/services.dart';

import '../../../app/theme.dart';
import '../../shared/scheduling/rating.dart';

/// 评分值 → 中文标签（'忘记'/'模糊'/'熟悉'），未知值原样返回。
String ratingDisplayLabel(String rating) => switch (rating) {
      Rating.forget => '忘记',
      Rating.vague => '模糊',
      Rating.familiar => '熟悉',
      _ => rating,
    };

/// 键盘数字键 → 评分值（1=忘记 / 2=模糊 / 3=熟悉），非数字键返回 null。
String? ratingOf(LogicalKeyboardKey key) => switch (key) {
      LogicalKeyboardKey.digit1 => Rating.forget,
      LogicalKeyboardKey.digit2 => Rating.vague,
      LogicalKeyboardKey.digit3 => Rating.familiar,
      _ => null,
    };

/// 评分后的「下次」间隔文案：间隔 > 0 委托 KarisTheme.intervalLabel；
/// 重学中 FAMILIAR 显示「继续」，其余显示「重学」（与 intervalLabel(0) 一致）。
String ratingNextLabel(String rating, int nextIntervalDays, bool learningMode) {
  if (nextIntervalDays > 0) return KarisTheme.intervalLabel(nextIntervalDays);
  return rating == Rating.familiar && learningMode ? '继续' : '重学';
}

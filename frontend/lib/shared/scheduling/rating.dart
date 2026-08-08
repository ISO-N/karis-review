/// 评分语义常量单一数据源（架构评审 E2，2026-08-08）。
///
/// 评分值此前在 UI、排期引擎、离线持久化、SQL 迁移、测试中散落 20+ 处
/// 字符串字面量（'FORGET'/'VAGUE'/'FAMILIAR'），改口径易漏。本类收敛为
/// 命名常量；DB 列与 API 线格式沿用这些字符串值（与后端 @Pattern 校验
/// 和后端评分枚举一致），代码内一律引用本类。
///
/// 注意：Drift 表列与历史 SQL 迁移内联的字符串值不可改（历史迁移不可变），
/// 本类值必须与之一致。
class Rating {
  Rating._();

  /// 忘记：重置 Stage 0 进入重学（FORGET 阈值 5）。
  static const String forget = 'FORGET';

  /// 模糊：降 1 级进入重学（VAGUE 阈值 3）。
  static const String vague = 'VAGUE';

  /// 熟悉：升级 1 级（或重学计数 +1）。
  static const String familiar = 'FAMILIAR';

  /// 全部合法评分值。
  static const List<String> values = [forget, vague, familiar];

  /// 校验字符串是否为合法评分值。
  static bool isValid(String? rating) =>
      rating == forget || rating == vague || rating == familiar;
}

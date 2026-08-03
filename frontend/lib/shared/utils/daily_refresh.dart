/// 计算从当前本地时间到下一次每日刷新点的等待时长。
///
/// 语义与 [LocalSchedulingEngine.calculateToday] 保持一致：
/// 当前时间在刷新点之前时，下一次刷新点仍是今天；否则是明天。
Duration nextDailyRefreshDelay(DateTime nowLocal, String refreshTime) {
  final parts = refreshTime.split(':');
  final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '4') ?? 4;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  final second = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;

  final todayBoundary = DateTime(
    nowLocal.year,
    nowLocal.month,
    nowLocal.day,
    hour,
    minute,
    second,
  );
  if (!nowLocal.isBefore(todayBoundary)) {
    return DateTime(
      nowLocal.year,
      nowLocal.month,
      nowLocal.day + 1,
      hour,
      minute,
      second,
    ).difference(nowLocal);
  }
  return todayBoundary.difference(nowLocal);
}

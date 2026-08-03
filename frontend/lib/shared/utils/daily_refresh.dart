import 'app_timezone.dart';

/// 计算从当前服务端 UTC 时间到下一次每日刷新点的等待时长。
///
/// 语义与 [LocalSchedulingEngine.calculateToday] 保持一致：
/// 当前时间在刷新点之前时，下一次刷新点仍是今天；否则是明天。
Duration nextDailyRefreshDelay(DateTime nowUtc, String refreshTime) {
  final now = serverUtcToBusiness(nowUtc);
  final parts = refreshTime.split(':');
  final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '4') ?? 4;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  final second = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;

  final todayBoundary = DateTime.utc(
    now.year,
    now.month,
    now.day,
    hour,
    minute,
    second,
  );
  final nextBoundary = !now.isBefore(todayBoundary)
      ? DateTime.utc(now.year, now.month, now.day + 1, hour, minute, second)
      : todayBoundary;
  return nextBoundary.subtract(appUtcOffset).difference(nowUtc.toUtc());
}

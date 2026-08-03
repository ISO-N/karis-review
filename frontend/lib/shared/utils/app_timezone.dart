/// 业务时区固定为 Asia/Shanghai（UTC+8）。
///
/// 后端 `app.timezone` 默认也是 Asia/Shanghai；这里不依赖设备时区，避免首页统计
/// 与服务端复习队列在 UTC 日期边界附近出现一天偏差。
library;

const Duration appUtcOffset = Duration(hours: 8);

DateTime serverUtcToBusiness(DateTime utc) {
  return utc.toUtc().add(appUtcOffset);
}

/// 解析服务端时间。
///
/// 带 `Z`/偏移的时间按 UTC 保留；无时区字符串按 Asia/Shanghai 墙上时间解释，
/// 再统一转成 UTC 存储，保证本地统计与后端使用同一个“今天”。
DateTime? parseServerDateTime(dynamic value) {
  if (value == null) return null;
  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null) return null;
  if (parsed.isUtc) return parsed;
  return DateTime.utc(
    parsed.year,
    parsed.month,
    parsed.day,
    parsed.hour,
    parsed.minute,
    parsed.second,
    parsed.millisecond,
    parsed.microsecond,
  ).subtract(appUtcOffset);
}

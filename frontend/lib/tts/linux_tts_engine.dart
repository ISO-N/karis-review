import 'dart:io';

import 'tts_engine.dart';
import 'tts_text_extractor.dart';

/// Linux TTS 引擎：spd-say 子进程（speech-dispatcher 命令行客户端）。
///
/// flutter_tts 不支持 Linux，这里直接调用系统 speech-dispatcher：
/// 每段文本启动一个 `spd-say -l <lang> -r <rate> -w <text>` 进程并等待读完，
/// [stop] 时 kill 当前进程并递增代数打断后续片段。
///
/// 系统依赖：speech-dispatcher + espeak-ng（Debian/Ubuntu：
/// `sudo apt install speech-dispatcher espeak-ng`）。未安装时
/// [isAvailable] 返回 false，上层静默降级（朗读按钮隐藏/禁用）。
class LinuxTtsEngine implements TtsEngine {
  Process? _current;
  int _generation = 0;
  bool _disposed = false;
  double _rate = 1.0;

  /// 已缓存的可执行文件路径；null 表示尚未探测。
  String? _spdSayPath;

  /// 探测 spd-say 是否可用。结果缓存，避免每次朗读都跑一次 which。
  Future<String?> _resolveSpdSay() async {
    if (_spdSayPath != null) return _spdSayPath;
    try {
      final result = await Process.run(
        'which',
        ['spd-say'],
        runInShell: true,
      );
      if (result.exitCode == 0 && result.stdout is String) {
        final path = (result.stdout as String).trim();
        _spdSayPath = path.isEmpty ? null : path;
      } else {
        _spdSayPath = null;
      }
    } catch (_) {
      _spdSayPath = null;
    }
    return _spdSayPath;
  }

  @override
  Future<bool> isAvailable() async {
    if (_disposed) return false;
    return (await _resolveSpdSay()) != null;
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    // speech-dispatcher 语速范围 -100..100（0 = 正常）。
    // 用户语速 0.5..1.5 线性映射到 -50..50。
    _rate = ((rate - 1.0) * 100).clamp(-100.0, 100.0);
  }

  @override
  Future<void> speakSegments(List<TtsSegment> segments) async {
    if (_disposed || segments.isEmpty) return;
    final spdSay = await _resolveSpdSay();
    if (spdSay == null) return;
    final generation = ++_generation;
    for (final segment in segments) {
      if (_disposed || generation != _generation) break;
      try {
        // -w 等待朗读完成；-l 语言（ISO 639）；-r 语速。
        final process = await Process.start(
          spdSay,
          [
            '-l',
            segment.language,
            '-r',
            _rate.round().toString(),
            '-w',
            segment.text,
          ],
          runInShell: true,
        );
        _current = process;
        await process.exitCode;
        if (identical(_current, process)) _current = null;
      } catch (_) {
        break;
      }
    }
  }

  @override
  Future<void> stop() async {
    _generation++;
    final current = _current;
    _current = null;
    try {
      current?.kill();
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await stop();
  }
}

import 'dart:io';

import 'linux_tts_engine.dart';
import 'system_tts_engine.dart';
import 'tts_text_extractor.dart';

/// TTS 引擎抽象。
///
/// 平台无关的朗读入口：接收已分段的朗读文本，负责逐段切换语言朗读。
/// 两个实现：
/// - [SystemTtsEngine]：flutter_tts（Android / iOS / Windows）；
/// - [LinuxTtsEngine]：spd-say 子进程（Linux，依赖 speech-dispatcher）。
///
/// 预留云端引擎扩展位：后续接神经网络 TTS 时实现同一接口即可无缝替换。
abstract class TtsEngine {
  /// 当前平台 TTS 是否可用（引擎存在且语言可加载）。
  Future<bool> isAvailable();

  /// 设置语速（0.5 = 慢，1.0 = 正常，1.5 = 快）。
  Future<void> setSpeechRate(double rate);

  /// 逐段朗读。实现必须保证 [stop] 可随时打断后续片段。
  Future<void> speakSegments(List<TtsSegment> segments);

  /// 停止当前朗读（幂等）。
  Future<void> stop();

  /// 释放资源（引擎句柄、子进程等）。
  Future<void> dispose();
}

/// 按当前平台创建引擎。Linux 用 spd-say 子进程，其余平台用 flutter_tts。
TtsEngine createTtsEngine() {
  if (Platform.isLinux) return LinuxTtsEngine();
  return SystemTtsEngine();
}

import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';

import 'tts_engine.dart';
import 'tts_text_extractor.dart';

/// 系统 TTS 引擎（flutter_tts 封装）：Android / iOS / Windows。
///
/// 逐段朗读策略：对每个 [TtsSegment] 先 setLanguage 再 speak，
/// 借助 awaitSpeakCompletion 串行等待；[stop] 通过代数（generation）
/// 递增打断循环，保证快速翻卡时不会残留后续片段朗读。
class SystemTtsEngine implements TtsEngine {
  final FlutterTts _tts = FlutterTts();
  // 测试环境（flutter test）下 flutter_tts 的 MethodChannel 调用在
  // fake async 里挂起而非抛 MissingPluginException，全部短路为 no-op，
  // 避免测试卡死；真实平台运行不受影响。
  final bool _testEnv = Platform.environment.containsKey('FLUTTER_TEST');
  double _rate = 1.0;
  int _generation = 0;
  bool _disposed = false;

  SystemTtsEngine() {
    if (_testEnv) return;
    _tts.setStartHandler(() {});
    _tts.setCompletionHandler(() {});
    _tts.setCancelHandler(() {});
    _tts.setErrorHandler((_) {});
    // iOS：与系统音量混音（朗读时音乐/视频可继续），避免抢占音频会话。
    if (Platform.isIOS) {
      _tts.setSharedInstance(true);
      _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.ambient,
        [IosTextToSpeechAudioCategoryOptions.mixWithOthers],
      );
    }
  }

  @override
  Future<bool> isAvailable() async {
    if (_disposed || _testEnv) return false;
    try {
      final languages = await _tts.getLanguages;
      return languages != null && languages.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    _rate = rate;
    if (_testEnv) return;
    try {
      await _tts.setSpeechRate(rate);
    } catch (_) {}
  }

  @override
  Future<void> speakSegments(List<TtsSegment> segments) async {
    if (_disposed || _testEnv || segments.isEmpty) return;
    final generation = ++_generation;
    try {
      await _tts.setSpeechRate(_rate);
      await _tts.awaitSpeakCompletion(true);
      for (final segment in segments) {
        if (_disposed || generation != _generation) break;
        await _tts.setLanguage(segment.language);
        if (_disposed || generation != _generation) break;
        await _tts.speak(segment.text);
        // speak 的 Future 在朗读完成或被打断时 resolve（awaitSpeakCompletion）。
      }
    } catch (_) {
      // 平台异常（如引擎初始化失败）静默降级：朗读中断不崩溃。
    }
  }

  @override
  Future<void> stop() async {
    _generation++;
    if (_testEnv) return;
    try {
      await _tts.stop();
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _generation++;
    if (_testEnv) return;
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

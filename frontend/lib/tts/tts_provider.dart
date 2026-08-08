import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tts_engine.dart';
import 'tts_text_extractor.dart';

/// 引擎实例（按平台选择，测试可覆盖替换）。
final ttsEngineProvider = Provider<TtsEngine>((ref) {
  return createTtsEngine();
});

class TtsState {
  /// 引擎可用（决定朗读按钮是否展示）。
  final bool available;

  /// 用户是否启用朗读（设置页开关）。
  final bool enabled;

  /// 语速 0.5..1.5。
  final double rate;

  /// 正在朗读（speakSegments 执行期间为 true）。
  final bool playing;

  /// 当前朗读的卡片面：'front' / 'back'。
  final String? readingSide;

  const TtsState({
    this.available = false,
    this.enabled = true,
    this.rate = 1.0,
    this.playing = false,
    this.readingSide,
  });

  TtsState copyWith({
    bool? available,
    bool? enabled,
    double? rate,
    bool? playing,
    String? readingSide,
    bool clearReadingSide = false,
  }) {
    return TtsState(
      available: available ?? this.available,
      enabled: enabled ?? this.enabled,
      rate: rate ?? this.rate,
      playing: playing ?? this.playing,
      readingSide: clearReadingSide ? null : (readingSide ?? this.readingSide),
    );
  }
}

/// 朗读状态管理：初始化探测、播放/停止、语速与开关偏好（存本地，不同步）。
class TtsNotifier extends StateNotifier<TtsState> {
  static const String _enabledKey = 'tts_enabled';
  static const String _rateKey = 'tts_rate';

  final TtsEngine _engine;
  bool _disposed = false;
  bool _initialized = false;

  TtsNotifier(this._engine) : super(const TtsState());

  TtsEngine get engine => _engine;

  /// 启动时探测引擎可用性并加载本地偏好。幂等。
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final available = await _engine.isAvailable();
    if (_disposed) return;
    final prefs = await SharedPreferences.getInstance();
    if (_disposed) return;
    final enabled = prefs.getBool(_enabledKey) ?? true;
    final rate = (prefs.getDouble(_rateKey) ?? 1.0).clamp(0.5, 1.5);
    await _engine.setSpeechRate(rate);
    if (_disposed) return;
    state = TtsState(available: available, enabled: enabled, rate: rate);
  }

  /// 朗读/停止切换：点击当前朗读面停止，否则先停旧再读新。
  /// content 为卡片某一面的原始内容（Delta/Markdown）。
  Future<void> toggle(String side, String content) async {
    if (!state.enabled || !state.available) return;
    if (state.playing && state.readingSide == side) {
      await stop();
      return;
    }
    await stop();

    final text = extractSpeakableText(content);
    if (text.isEmpty) return;
    final segments = splitForSpeech(text);
    if (segments.isEmpty) return;

    state = state.copyWith(playing: true, readingSide: side);
    await _engine.speakSegments(segments);
    if (!_disposed) {
      state = state.copyWith(playing: false, clearReadingSide: true);
    }
  }

  /// 停止朗读（幂等，换卡/翻面/离页时调用）。
  Future<void> stop() async {
    await _engine.stop();
    if (!_disposed && state.playing) {
      state = state.copyWith(playing: false, clearReadingSide: true);
    }
  }

  /// 设置语速并持久化。
  Future<void> setRate(double rate) async {
    final clamped = rate.clamp(0.5, 1.5);
    await _engine.setSpeechRate(clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_rateKey, clamped);
    if (!_disposed) state = state.copyWith(rate: clamped);
  }

  /// 设置开关并持久化；关闭时立即停止朗读。
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    if (!_disposed) state = state.copyWith(enabled: enabled);
    if (!enabled) await stop();
  }

  @override
  void dispose() {
    _disposed = true;
    _engine.dispose();
    super.dispose();
  }
}

final ttsProvider = StateNotifierProvider<TtsNotifier, TtsState>((ref) {
  return TtsNotifier(ref.watch(ttsEngineProvider));
});

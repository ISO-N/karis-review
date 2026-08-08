import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tts_text_extractor.dart';

/// 美式 IPA 音标词库（open-dict-data/ipa-dict `en_US`，CC0 许可）。
///
/// 纯客户端离线查询，不碰后端：词库作为 Flutter asset 打包，
/// 首次查询时惰性加载并解析为 `word -> IPA` 映射，查询结果走 LRU 缓存。
///
/// 规则：
/// - 只对"纯英文单词/短语"（无中文、数字、标点，允许撇号/连字符/空格）
///   显示音标，避免中英混合卡与句子卡的噪音；
/// - 一词多音标（如 record 名词/动词重音不同）取第一个（主要发音）；
/// - 多词按空格逐词拼接；连字符词整体查不到时按 `-` 拆开回退；
/// - 词库查不到（生僻词、专有名词）返回 null，调用方静默不显示。
class PhoneticDict {
  static const String assetPath = 'assets/ipa/en_US_ipa.txt';
  static const int _cacheLimit = 256;

  static final RegExp _englishPhrasePattern =
      RegExp(r"^[A-Za-z][A-Za-z' -]{0,39}$");

  Map<String, String>? _words;
  Future<void>? _loading;
  final LinkedHashMap<String, String> _cache = LinkedHashMap();

  /// 可注入预置词库（测试用）；不传则首次查询时从 asset 加载。
  PhoneticDict({Map<String, String>? seedWords}) {
    if (seedWords != null) {
      _words = seedWords;
      _loading = Future.value();
    }
  }

  /// 判定文本是否为"纯英文单词/短语"（最多 40 字符）。
  bool isEnglishPhrase(String text) {
    final t = text.trim();
    if (t.isEmpty || t.length > 40) return false;
    return _englishPhrasePattern.hasMatch(t);
  }

  /// 查询音标。content 为卡片某面的原始内容（Delta/Markdown/纯文本），
  /// 内部先提取朗读文本再判定，保证 Delta 卡也能命中。
  Future<String?> phoneticFor(String content) async {
    final text = extractSpeakableText(content);
    if (!isEnglishPhrase(text)) return null;

    final cached = _cache.remove(text);
    if (cached != null) {
      _cache[text] = cached;
      return cached;
    }

    await _ensureLoaded();
    final result = _lookup(text);
    if (result != null) {
      _cache[text] = result;
      if (_cache.length > _cacheLimit) {
        _cache.remove(_cache.keys.first);
      }
    }
    return result;
  }

  Future<void> _ensureLoaded() {
    return _loading ??= _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString(assetPath);
    final words = <String, String>{};
    for (final line in LineSplitter.split(raw)) {
      final idx = line.indexOf('\t');
      if (idx <= 0) continue;
      final word = line.substring(0, idx).toLowerCase();
      // 多音标逗号分隔取第一个；音标本身带 /.../ 包裹，存储时去掉，
      // 渲染层统一包斜杠。
      final ipa = line
          .substring(idx + 1)
          .trim()
          .split(',')
          .first
          .trim()
          .replaceAll(RegExp(r'^/+|/+$'), '');
      if (ipa.isEmpty) continue;
      words[word] = ipa;
    }
    _words = words;
  }

  String? _lookup(String text) {
    final words = _words;
    if (words == null) return null;
    final parts = text.split(' ');
    final ipas = <String>[];
    for (final part in parts) {
      final ipa = _lookupWord(part, words);
      if (ipa == null) return null;
      ipas.add(ipa);
    }
    return ipas.join(' ');
  }

  String? _lookupWord(String word, Map<String, String> words) {
    final lower = word.toLowerCase();
    final direct = words[lower];
    if (direct != null) return direct;
    // 连字符合成词（well-known）整体查不到时按段回退。
    if (lower.contains('-')) {
      final parts = lower.split('-');
      final ipas = <String>[];
      for (final p in parts) {
        final ipa = words[p];
        if (ipa == null) return null;
        ipas.add(ipa);
      }
      return ipas.join(' ');
    }
    return null;
  }
}

/// 词库实例（全局共享：加载一次、缓存复用）。
final phoneticDictProvider = Provider<PhoneticDict>((ref) {
  return PhoneticDict();
});

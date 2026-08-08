import 'package:flutter_test/flutter_test.dart';
import 'package:karisreview/tts/phonetic_dict.dart';

void main() {
  group('isEnglishPhrase', () {
    final dict = PhoneticDict();

    test('纯英文单词/短语通过', () {
      expect(dict.isEnglishPhrase('abandon'), isTrue);
      expect(dict.isEnglishPhrase('give up'), isTrue);
      expect(dict.isEnglishPhrase("don't"), isTrue);
      expect(dict.isEnglishPhrase('well-known'), isTrue);
    });

    test('中文/混合/数字/标点/句子拒绝', () {
      expect(dict.isEnglishPhrase('abandon 抛弃'), isFalse);
      expect(dict.isEnglishPhrase('抛弃'), isFalse);
      expect(dict.isEnglishPhrase('word2'), isFalse);
      expect(dict.isEnglishPhrase('E=mc²'), isFalse);
      expect(dict.isEnglishPhrase('The quick brown fox jumps.'), isFalse);
      expect(dict.isEnglishPhrase('hello.'), isFalse);
      expect(dict.isEnglishPhrase(''), isFalse);
    });

    test('超长内容拒绝', () {
      expect(dict.isEnglishPhrase('a' * 41), isFalse);
    });
  });

  group('phoneticFor（注入词库）', () {
    final dict = PhoneticDict(
      seedWords: {
        'abandon': 'əˈbændən',
        'give': 'ɡɪv',
        'up': 'ʌp',
        'paris': 'ˈpæɹɪs',
        'record': 'ˈɹɛkɝd',
        'well': 'wɛl',
        'known': 'noʊn',
      },
    );

    test('查询单词音标', () async {
      expect(await dict.phoneticFor('abandon'), 'əˈbændən');
    });

    test('大小写归一化', () async {
      expect(await dict.phoneticFor('Paris'), 'ˈpæɹɪs');
    });

    test('多词逐词拼接', () async {
      expect(await dict.phoneticFor('give up'), 'ɡɪv ʌp');
    });

    test('连字符合成词回退拆段', () async {
      expect(await dict.phoneticFor('well-known'), 'wɛl noʊn');
    });

    test('非英文内容返回 null', () async {
      expect(await dict.phoneticFor('abandon 抛弃'), isNull);
      expect(await dict.phoneticFor('句子内容'), isNull);
    });

    test('词库未收录返回 null', () async {
      expect(await dict.phoneticFor('zzzqxqz'), isNull);
    });

    test('查询结果缓存复用', () async {
      final first = await dict.phoneticFor('abandon');
      final second = await dict.phoneticFor('abandon');
      expect(first, second);
      expect(first, 'əˈbændən');
    });
  });

  group('phoneticFor（真实 asset 词库）', () {
    testWidgets('加载真实词库并查询', (tester) async {
      final dict = PhoneticDict();
      // runAsync：asset 加载是真实 IO，fake async 下会挂起。
      final ipa = await tester.runAsync(() => dict.phoneticFor('abandon'));
      expect(ipa, 'əˈbændən');
    });
  });
}

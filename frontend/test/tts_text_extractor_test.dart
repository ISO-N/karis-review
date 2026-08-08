import 'package:flutter_test/flutter_test.dart';
import 'package:karisreview/tts/tts_text_extractor.dart';

void main() {
  group('extractSpeakableText', () {
    test('纯文本原样返回', () {
      expect(extractSpeakableText('Hello world'), 'Hello world');
    });

    test('Delta JSON 提取文本并跳过 latex/code embed', () {
      const delta = '''
      [
        {"insert": "abandon"},
        {"insert": {"latex": "{\\"latex\\": \\"x^2\\"}"}},
        {"insert": "\\n"},
        {"insert": {"code": "{\\"language\\":\\"dart\\",\\"code\\":\\"void main(){}\\"}"}},
        {"insert": " 抛弃"}
      ]''';
      expect(extractSpeakableText(delta), 'abandon\n 抛弃');
    });

    test('Delta 首字符是 [ 但解析失败时回退 Markdown', () {
      expect(extractSpeakableText('[not a delta'), '[not a delta');
    });

    test('Markdown 剥离代码围栏', () {
      const md = '解释一下\n```dart\nvoid main() { print(1); }\n```\n结束';
      expect(extractSpeakableText(md), '解释一下\n结束');
    });

    test('Markdown 剥离行间与行内公式', () {
      const md = r'勾股定理：$$a^2 + b^2 = c^2$$ 以及行内 $E=mc^2$ 公式';
      expect(extractSpeakableText(md), '勾股定理： 以及行内 公式');
    });

    test('Markdown 剥离格式保留文本', () {
      const md = '**重点** 与 *斜体* 与 `inline code`';
      expect(extractSpeakableText(md), '重点 与 斜体 与 inline code');
    });

    test('Markdown 标题与列表', () {
      const md = '# 标题\n- 项目一\n- 项目二';
      expect(extractSpeakableText(md), '标题\n项目一\n项目二');
    });

    test('空内容返回空串', () {
      expect(extractSpeakableText(''), '');
      expect(extractSpeakableText('   '), '');
    });
  });

  group('detectLanguage', () {
    test('纯中文判 zh-CN', () {
      expect(detectLanguage('抛弃'), 'zh-CN');
      expect(detectLanguage('你好，世界'), 'zh-CN');
    });

    test('纯英文判 en-US', () {
      expect(detectLanguage('abandon'), 'en-US');
      expect(detectLanguage('Hello world'), 'en-US');
    });

    test('中英混合含两个以上汉字判 zh-CN', () {
      expect(detectLanguage('abandon 抛弃'), 'zh-CN');
      expect(detectLanguage('abandon 的意思是抛弃'), 'zh-CN');
    });

    test('无字母数字标点默认 en-US', () {
      expect(detectLanguage('12345'), 'en-US');
    });
  });

  group('splitForSpeech', () {
    test('按句切分并合并相邻同语言', () {
      final segs = splitForSpeech('hello world。今天是好天气。See you tomorrow');
      expect(segs, [
        TtsSegment('hello world。', 'en-US'),
        TtsSegment('今天是好天气。', 'zh-CN'),
        TtsSegment('See you tomorrow', 'en-US'),
      ]);
    });

    test('连续中文句子合并为一段', () {
      final segs = splitForSpeech('第一句。第二句！第三句？');
      expect(segs, [TtsSegment('第一句。 第二句！ 第三句？', 'zh-CN')]);
    });

    test('空文本返回空列表', () {
      expect(splitForSpeech(''), isEmpty);
      expect(splitForSpeech('   '), isEmpty);
    });
  });
}

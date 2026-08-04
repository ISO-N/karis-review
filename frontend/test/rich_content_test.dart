import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:karisreview/shared/widgets/rich_card_content.dart';

void main() {
  test('CodeEmbed.tryDecode handles direct and outer formats', () {
    const direct = '{"language":"dart","code":"void main() {}"}';
    const outer =
        '{"code":"{\\"language\\":\\"dart\\",\\"code\\":\\"void main() {}\\"}"}';
    final directResult = CodeEmbed.tryDecode(direct);
    final outerResult = CodeEmbed.tryDecode(outer);
    expect(directResult, isNotNull);
    expect(directResult!.$1, 'dart');
    expect(directResult.$2, 'void main() {}');
    expect(outerResult, isNotNull);
    expect(outerResult!.$1, 'dart');
    expect(outerResult.$2, 'void main() {}');
  });

  test('Quill delta with code embed parses and exposes code text', () {
    final deltaJson = jsonEncode([
      {
        'insert': {
          'code': jsonEncode({'language': 'dart', 'code': 'void main() {}'}),
        },
      },
      {'insert': '\n'},
    ]);

    final doc = quill.Document.fromJson(jsonDecode(deltaJson) as List<dynamic>);
    expect(doc.toPlainText(), isNot(contains('language')));
  });

  testWidgets('Delta preview uses light text instead of QuillEditor', (
    tester,
  ) async {
    final delta = jsonEncode([
      {'insert': '你好\n'},
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RichCardContent(content: delta, maxLines: 2)),
      ),
    );

    expect(find.byType(quill.QuillEditor), findsNothing);
    expect(find.textContaining('你好'), findsOneWidget);
  });

  testWidgets('Full Delta content keeps Quill rendering', (tester) async {
    final delta = jsonEncode([
      {'insert': '完整内容\n'},
    ]);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates:
            quill.FlutterQuillLocalizations.localizationsDelegates,
        supportedLocales: quill.FlutterQuillLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(body: RichCardContent(content: delta)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(quill.QuillEditor), findsOneWidget);
  });

  testWidgets('Long inline math scrolls horizontally', (tester) async {
    const content =
        r'等式：$\frac{1}{2}+\frac{1}{3}+\frac{1}{4}+\frac{1}{5}+\frac{1}{6}+\frac{1}{7}+\frac{1}{8}+\frac{1}{9}+\frac{1}{10}+\frac{1}{11}+\frac{1}{12} = \frac{1}{13}$ 成立';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              child: RichCardContent(content: content),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(SingleChildScrollView);
    expect(scrollable, findsOneWidget);
    expect(
      tester.widget<SingleChildScrollView>(scrollable).scrollDirection,
      Axis.horizontal,
    );

    final scrollableState = tester.state<ScrollableState>(
      find.descendant(of: scrollable, matching: find.byType(Scrollable)).first,
    );
    expect(scrollableState.position.maxScrollExtent, greaterThan(0));

    await tester.drag(scrollable, const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(scrollableState.position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Long display math scrolls horizontally', (tester) async {
    const content =
        r'$$\int_0^1 \frac{1}{1+x^2}\,dx + \frac{1}{2}+\frac{1}{3}+\frac{1}{4}+\frac{1}{5}+\frac{1}{6}+\frac{1}{7}+\frac{1}{8}+\frac{1}{9}+\frac{1}{10}+\frac{1}{11}+\frac{1}{12} = \frac{\pi}{4}$$';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              child: RichCardContent(content: content),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(SingleChildScrollView);
    expect(scrollable, findsOneWidget);
    final scrollableState = tester.state<ScrollableState>(
      find.descendant(of: scrollable, matching: find.byType(Scrollable)).first,
    );
    expect(scrollableState.position.maxScrollExtent, greaterThan(0));

    await tester.drag(scrollable, const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(scrollableState.position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Plain text without math keeps wrapping', (tester) async {
    const content = '这是一段没有公式的普通文本，用于确认不含公式的行仍然按宽度自动换行。';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 120,
              child: RichCardContent(content: content),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

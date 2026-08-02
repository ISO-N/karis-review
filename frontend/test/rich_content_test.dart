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
}

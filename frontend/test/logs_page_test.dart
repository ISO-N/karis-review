import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karisreview/l10n/app_localizations.dart';
import 'package:karisreview/log/pages/logs_page.dart';
import 'package:karisreview/log/providers/logs_provider.dart';
import 'package:karisreview/log/repositories/logs_repository.dart';

import 'helpers/test_helpers.dart';

Widget _app(FakeApiClient client) {
  return ProviderScope(
    overrides: [
      logsProvider.overrideWith((ref) => LogsNotifier(LogsRepository(client: client))),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        KarisReviewLocalizations.delegate,
      ],
      supportedLocales: KarisReviewLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: const LogsPage(),
    ),
  );
}

void main() {
  testWidgets('logs page renders entries and expands details', (tester) async {
    final client = FakeApiClient();
    client.onGet = (_, _) async => okResponse({
          'content': [
            {
              'id': 'log-1',
              'level': 'ERROR',
              'category': 'SYNC',
              'message': '同步失败',
              'details': {'card_id': 'card-1'},
              'created_at': '2025-08-02T12:00:00Z',
            },
          ],
          'page': 0,
          'total_pages': 1,
        });

    await tester.pumpWidget(_app(client));
    await tester.pumpAndSettle();

    expect(find.text('同步失败'), findsOneWidget);
    expect(find.text('ERROR'), findsOneWidget);

    await tester.tap(find.text('同步失败'));
    await tester.pumpAndSettle();

    expect(find.textContaining('card_id'), findsOneWidget);
  });

  testWidgets('logs page shows empty state', (tester) async {
    final client = FakeApiClient();
    client.onGet = (_, _) async => okResponse({
          'content': [],
          'page': 0,
          'total_pages': 1,
        });

    await tester.pumpWidget(_app(client));
    await tester.pumpAndSettle();

    expect(find.text('暂无日志'), findsOneWidget);
  });

  testWidgets('logs page retries after error', (tester) async {
    final client = FakeApiClient();
    var calls = 0;
    client.onGet = (_, _) async {
      calls += 1;
      if (calls == 1) throw apiError('日志加载失败');
      return okResponse({
        'content': [
          {
            'id': 'log-2',
            'level': 'INFO',
            'category': 'AUTH',
            'message': '登录成功',
            'details': null,
            'created_at': '2025-08-02T12:00:00Z',
          },
        ],
        'page': 0,
        'total_pages': 1,
      });
    };

    await tester.pumpWidget(_app(client));
    await tester.pumpAndSettle();

    expect(find.textContaining('日志加载失败'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    expect(find.text('登录成功'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:karisreview/log/providers/logs_provider.dart';
import 'package:karisreview/log/repositories/logs_repository.dart';

import 'helpers/test_helpers.dart';

void main() {
  test('loadLogs parses first page', () async {
    final client = FakeApiClient();
    client.onGet = (path, _) async {
      final uri = Uri.parse(path);
      expect(uri.queryParameters['page'], '0');
      return okResponse({
        'content': [
          logJson('log-1'),
        ],
        'page': 0,
        'total_pages': 2,
      });
    };
    final notifier = LogsNotifier(LogsRepository(client: client));

    await notifier.loadLogs();

    expect(notifier.state.logs, hasLength(1));
    expect(notifier.state.page, 0);
    expect(notifier.state.hasMore, isTrue);
  });

  test('loadMore appends next page', () async {
    final client = FakeApiClient();
    client.onGet = (path, _) async {
      final uri = Uri.parse(path);
      final page = uri.queryParameters['page'];
      if (page == '0') {
        return okResponse({
          'content': [logJson('log-1')],
          'page': 0,
          'total_pages': 2,
        });
      }
      expect(page, '1');
      return okResponse({
        'content': [logJson('log-2')],
        'page': 1,
        'total_pages': 2,
      });
    };
    final notifier = LogsNotifier(LogsRepository(client: client));
    await notifier.loadLogs();

    await notifier.loadMore();

    expect(notifier.state.logs.map((e) => e.id), ['log-1', 'log-2']);
    expect(notifier.state.hasMore, isFalse);
  });

  test('filters reload from page zero', () async {
    final client = FakeApiClient();
    client.onGet = (path, _) async {
      final uri = Uri.parse(path);
      expect(uri.queryParameters['level'], 'ERROR');
      return okResponse({
        'content': [logJson('log-error')],
        'page': 0,
        'total_pages': 1,
      });
    };
    final notifier = LogsNotifier(LogsRepository(client: client));

    await notifier.setLevelFilter('ERROR');

    expect(notifier.state.levelFilter, 'ERROR');
    expect(notifier.state.logs.single.level, 'ERROR');
  });

  test('loadLogs stores error state', () async {
    final client = FakeApiClient();
    client.onGet = (_, _) async => throw apiError('日志加载失败');
    final notifier = LogsNotifier(LogsRepository(client: client));

    await notifier.loadLogs();

    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.error, contains('日志加载失败'));
  });
}

Map<String, dynamic> logJson(String id) {
  return {
    'id': id,
    'level': 'ERROR',
    'category': 'REVIEW',
    'message': 'sync failed',
    'details': null,
    'created_at': '2025-08-02T12:00:00Z',
  };
}

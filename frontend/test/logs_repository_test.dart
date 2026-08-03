import 'package:flutter_test/flutter_test.dart';
import 'package:karisreview/log/repositories/logs_repository.dart';

import 'helpers/test_helpers.dart';

void main() {
  test('getLogs sends default page and size', () async {
    final client = FakeApiClient();
    client.onGet = (path, query) async {
      final uri = Uri.parse(path);
      expect(uri.queryParameters, {'page': '0', 'size': '50'});
      return okResponse({
        'content': [
          {
            'id': 'log-1',
            'level': 'INFO',
            'category': 'AUTH',
            'message': 'ok',
            'details': null,
            'created_at': '2025-08-02T12:00:00Z',
          },
        ],
        'page': 0,
        'size': 50,
        'total_elements': 1,
        'total_pages': 1,
      });
    };
    final repository = LogsRepository(client: client);

    final data = await repository.getLogs();

    expect((data['content'] as List).single['level'], 'INFO');
    expect(data['page'], 0);
  });

  test('getLogs sends level and category filters', () async {
    final client = FakeApiClient();
    client.onGet = (path, query) async {
      final uri = Uri.parse(path);
      expect(uri.queryParameters, {
        'page': '2',
        'size': '20',
        'level': 'ERROR',
        'category': 'SYNC',
      });
      return okResponse({'content': [], 'page': 2, 'total_pages': 1});
    };
    final repository = LogsRepository(client: client);

    await repository.getLogs(page: 2, size: 20, level: 'ERROR', category: 'SYNC');
  });
}

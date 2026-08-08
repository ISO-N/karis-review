import 'package:flutter_test/flutter_test.dart';

import 'package:karisreview/shared/proto/karis_review.pb.dart' as proto;
import 'package:karisreview/shared/proto/proto_mappers.dart';

void main() {
  group('reviewLogToMap', () {
    test('保留 learning_origin（回归：曾漏映射导致本地统计误计学新重学）', () {
      final map = reviewLogToMap(
        proto.ReviewLog(
          id: 'log-1',
          cardId: 'card-1',
          rating: 'FAMILIAR',
          stageBefore: 0,
          stageAfter: 0,
          reviewedAt: '2026-08-08T10:00:00',
          isNewCard: false,
          learningOrigin: 'NEW',
          clientRequestId: 'req-1',
        ),
      );

      expect(map['learning_origin'], 'NEW');
      expect(map['is_new_card'], false);
      expect(map['client_request_id'], 'req-1');
    });

    test('learning_origin 为空时映射为 null', () {
      final map = reviewLogToMap(
        proto.ReviewLog(
          id: 'log-2',
          cardId: 'card-2',
          rating: 'FAMILIAR',
          stageBefore: 1,
          stageAfter: 2,
          reviewedAt: '2026-08-08T10:00:00',
          isNewCard: false,
        ),
      );

      expect(map['learning_origin'], isNull);
    });
  });
}

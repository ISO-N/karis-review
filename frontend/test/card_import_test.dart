import 'package:flutter_test/flutter_test.dart';
import 'package:karisreview/card/models/card_import.dart';

void main() {
  test('CardImportPreviewItem parses backend preview row', () {
    final item = CardImportPreviewItem.fromJson({
      'index': 2,
      'front': '正面',
      'back': '反面',
      'valid': true,
      'message': null,
    });

    expect(item.index, 2);
    expect(item.front, '正面');
    expect(item.back, '反面');
    expect(item.valid, isTrue);
    expect(item.message, isNull);
  });

  test('CardImportPreviewItem defaults invalid rows to empty content', () {
    final item = CardImportPreviewItem.fromJson({
      'index': 0,
      'valid': false,
      'message': '卡片必须是对象',
    });

    expect(item.front, '');
    expect(item.back, '');
    expect(item.valid, isFalse);
    expect(item.message, '卡片必须是对象');
  });

  test('CardImportPreviewItem copyWith updates editable fields', () {
    const item = CardImportPreviewItem(
      index: 1,
      front: '',
      back: '旧反面',
      valid: false,
      message: '正面内容不能为空',
    );

    final updated = item.copyWith(
      front: '新正面',
      valid: true,
      clearMessage: true,
    );

    expect(updated.index, 1);
    expect(updated.front, '新正面');
    expect(updated.back, '旧反面');
    expect(updated.valid, isTrue);
    expect(updated.message, isNull);
  });
}

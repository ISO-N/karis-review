import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karisreview/review/models/rating_labels.dart';

void main() {
  group('ratingDisplayLabel', () {
    test('maps ratings to Chinese labels', () {
      expect(ratingDisplayLabel('FORGET'), '忘记');
      expect(ratingDisplayLabel('VAGUE'), '模糊');
      expect(ratingDisplayLabel('FAMILIAR'), '熟悉');
    });

    test('passes through unknown values', () {
      expect(ratingDisplayLabel('CUSTOM'), 'CUSTOM');
    });
  });

  group('ratingOf', () {
    test('maps digit keys to ratings', () {
      expect(ratingOf(LogicalKeyboardKey.digit1), 'FORGET');
      expect(ratingOf(LogicalKeyboardKey.digit2), 'VAGUE');
      expect(ratingOf(LogicalKeyboardKey.digit3), 'FAMILIAR');
    });

    test('returns null for non-digit keys', () {
      expect(ratingOf(LogicalKeyboardKey.keyA), isNull);
      expect(ratingOf(LogicalKeyboardKey.space), isNull);
    });
  });

  group('ratingNextLabel', () {
    test('positive interval uses interval label', () {
      expect(ratingNextLabel('FAMILIAR', 7, false), '7 天');
      expect(ratingNextLabel('VAGUE', 1, false), '1 天');
    });

    test('relearning familiar shows continue', () {
      expect(ratingNextLabel('FAMILIAR', 0, true), '继续');
    });

    test('zero interval otherwise shows relearning', () {
      expect(ratingNextLabel('VAGUE', 0, true), '重学');
      expect(ratingNextLabel('FORGET', 0, false), '重学');
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karisreview/app/app.dart';

void main() {
  testWidgets('App starts and shows login page', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: KarisReviewApp()));
    expect(find.text('Karis Review'), findsOneWidget);
  });
}
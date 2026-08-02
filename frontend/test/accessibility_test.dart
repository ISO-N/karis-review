import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karisreview/shared/utils/motion.dart';
import 'package:karisreview/shared/widgets/app_semantics.dart';

void main() {
  testWidgets('KarisHeading exposes header semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: KarisHeading(child: Text('页面标题'))),
      ),
    );

    final node = tester.getSemantics(find.text('页面标题'));
    expect(node.flagsCollection.isHeader, isTrue);
    handle.dispose();
  });

  testWidgets('KarisInteractive exposes button and selected semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: KarisInteractive(selected: true, child: Text('选项')),
        ),
      ),
    );

    final node = tester.getSemantics(find.text('选项'));
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.flagsCollection.isSelected, Tristate.isTrue);
    handle.dispose();
  });

  testWidgets('reducedDuration honors disableAnimations', (tester) async {
    Duration? actual;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              actual = reducedDuration(
                context,
                const Duration(milliseconds: 300),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(actual, Duration.zero);
  });

  testWidgets('reducedDuration keeps duration when animations enabled', (
    tester,
  ) async {
    Duration? actual;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            actual = reducedDuration(
              context,
              const Duration(milliseconds: 300),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(actual, const Duration(milliseconds: 300));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:karisreview/auth/models/login_request.dart';
import 'package:karisreview/auth/models/login_response.dart';
import 'package:karisreview/auth/pages/login_page.dart';
import 'package:karisreview/auth/pages/register_page.dart';
import 'package:karisreview/card/pages/card_list_page.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:karisreview/card/pages/card_editor_page.dart';
import 'package:karisreview/card/pages/card_import_page.dart';
import 'package:karisreview/deck/models/deck.dart';
import 'package:karisreview/deck/pages/deck_list_page.dart';
import 'package:karisreview/home/pages/home_page.dart';
import 'package:karisreview/review/models/review_card.dart';
import 'package:karisreview/review/pages/review_page.dart';
import 'package:karisreview/review/providers/review_provider.dart';
import 'package:karisreview/review/widgets/review_flip_card.dart';
import 'package:karisreview/review/pages/start_flow_page.dart';
import 'package:karisreview/settings/pages/settings_page.dart';
import 'package:karisreview/shared/widgets/adaptive_scaffold.dart';
import 'package:karisreview/shared/widgets/metric_tile.dart';
import 'package:karisreview/stats/pages/stats_page.dart';
import 'package:karisreview/stats/models/stats.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('zh_CN');
    registerFallbackValue(
      LoginRequest(email: 'fallback@example.com', password: 'fallback'),
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Auth pages', () {
    testWidgets('login validates and submits credentials', (tester) async {
      final repo = MockAuthRepository();
      when(() => repo.isLoggedIn()).thenAnswer((_) async => false);
      when(
        () => repo.login(any()),
      ).thenAnswer((_) async => loginResponse('a@b.c'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: authOverrides(repo),
          child: const MaterialApp(home: LoginPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('登录'));
      await tester.pump();
      expect(find.text('请输入邮箱'), findsOneWidget);
      expect(find.text('请输入密码'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'a@b.c');
      await tester.enterText(find.byType(TextFormField).at(1), 'secret');
      await tester.tap(find.text('登录'));
      await tester.pumpAndSettle();

      verify(() => repo.login(any())).called(1);
    });

    testWidgets('register submits account', (tester) async {
      final repo = MockAuthRepository();
      when(() => repo.isLoggedIn()).thenAnswer((_) async => false);
      when(
        () => repo.register(any()),
      ).thenAnswer((_) async => loginResponse('a@b.c'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: authOverrides(repo),
          child: const MaterialApp(home: RegisterPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'a@b.c');
      await tester.enterText(find.byType(TextFormField).at(1), 'secret');
      await tester.enterText(find.byType(TextFormField).at(2), 'secret');
      await tester.tap(find.text('注册'));
      await tester.pumpAndSettle();

      verify(() => repo.register(any())).called(1);
    });
  });

  group('Dashboard pages', () {
    testWidgets('home renders today and deck data', (tester) async {
      final authRepo = MockAuthRepository();
      when(() => authRepo.isLoggedIn()).thenAnswer((_) async => false);
      final deckRepo = MockDeckRepository();
      when(
        () => deckRepo.getDecks(),
      ).thenAnswer((_) async => [Deck.fromJson(deckJson())]);
      final statsRepo = MockStatsRepository();
      when(
        () => statsRepo.getOverview(),
      ).thenAnswer((_) async => OverviewStats.fromJson(overviewStatsJson()));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...authOverrides(authRepo),
            ...deckOverrides(deckRepo),
            ...statsOverrides(statsRepo),
          ],
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('今日待复习'), findsOneWidget);
      expect(find.text('日语 N5'), findsWidgets);
    });

    testWidgets('deck list renders rows and empty state', (tester) async {
      final repo = MockDeckRepository();
      when(
        () => repo.getDecks(),
      ).thenAnswer((_) async => [Deck.fromJson(deckJson())]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: deckOverrides(repo),
          child: const MaterialApp(home: DeckListPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('日语 N5'), findsOneWidget);
      expect(find.text('2 张 · 待复习 1'), findsOneWidget);
    });

    testWidgets('deck list renders empty state', (tester) async {
      final emptyRepo = MockDeckRepository();
      when(() => emptyRepo.getDecks()).thenAnswer((_) async => []);
      await tester.pumpWidget(
        ProviderScope(
          overrides: deckOverrides(emptyRepo),
          child: const MaterialApp(home: DeckListPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('还没有牌组'), findsOneWidget);
    });

    testWidgets('start flow switches between review and new cards', (
      tester,
    ) async {
      final repo = MockDeckRepository();
      when(
        () => repo.getDecks(),
      ).thenAnswer((_) async => [Deck.fromJson(deckJson())]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: deckOverrides(repo),
          child: const MaterialApp(home: StartFlowPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('开始复习'), findsWidgets);
      await tester.tap(find.text('学习新卡'));
      await tester.pumpAndSettle();
      expect(find.text('开始学习'), findsWidgets);
    });

    testWidgets('card list renders cards and filters', (tester) async {
      final cardRepo = MockCardRepository();
      when(
        () => cardRepo.getDeckCards('deck-1', size: 500, filter: 'all'),
      ).thenAnswer(
        (_) async => {
          'content': [cardJson(front: '正面内容')],
        },
      );
      final statsRepo = MockStatsRepository();
      when(
        () => statsRepo.getOverview(),
      ).thenAnswer((_) async => OverviewStats.fromJson(overviewStatsJson()));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [...cardOverrides(cardRepo), ...statsOverrides(statsRepo)],
          child: const MaterialApp(home: CardListPage(deckId: 'deck-1')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('日语 N5'), findsOneWidget);
      expect(find.text('正面内容'), findsOneWidget);

      await tester.tap(find.text('待复习'));
      await tester.pumpAndSettle();
      expect(find.text('全部'), findsOneWidget);
    });

    testWidgets('card list lazily builds cards with CustomScrollView', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final cardRepo = MockCardRepository();
      when(
        () => cardRepo.getDeckCards('deck-1', size: 500, filter: 'all'),
      ).thenAnswer(
        (_) async => {
          'content': [
            for (var i = 0; i < 50; i++)
              cardJson(id: 'card-$i', front: '卡片 $i'),
          ],
        },
      );
      final statsRepo = MockStatsRepository();
      when(
        () => statsRepo.getOverview(),
      ).thenAnswer((_) async => OverviewStats.fromJson(overviewStatsJson()));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [...cardOverrides(cardRepo), ...statsOverrides(statsRepo)],
          child: const MaterialApp(home: CardListPage(deckId: 'deck-1')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.text('卡片 0'), findsOneWidget);
      expect(find.text('卡片 49'), findsNothing);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -4000));
      await tester.pumpAndSettle();
      expect(find.text('卡片 49'), findsOneWidget);
    });
    testWidgets('card list opens editor and import as standalone routes', (
      tester,
    ) async {
      final cardRepo = MockCardRepository();
      when(
        () => cardRepo.getDeckCards('deck-1', size: 500, filter: 'all'),
      ).thenAnswer(
        (_) async => {
          'content': [cardJson(front: '正面内容')],
        },
      );
      final statsRepo = MockStatsRepository();
      when(
        () => statsRepo.getOverview(),
      ).thenAnswer((_) async => OverviewStats.fromJson(overviewStatsJson()));

      final router = GoRouter(
        initialLocation: '/decks/deck-1/cards',
        routes: [
          GoRoute(
            path: '/decks/:deckId/cards',
            builder: (_, state) =>
                CardListPage(deckId: state.pathParameters['deckId']!),
          ),
          GoRoute(
            path: '/decks/:deckId/cards/editor',
            builder: (_, state) {
              final extra = state.extra;
              return CardEditorPage(
                args: extra is CardEditorArgs
                    ? extra
                    : CardEditorArgs(deckId: state.pathParameters['deckId']!),
              );
            },
          ),
          GoRoute(
            path: '/decks/:deckId/cards/import',
            builder: (_, state) =>
                CardImportPage(deckId: state.pathParameters['deckId']!),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [...cardOverrides(cardRepo), ...statsOverrides(statsRepo)],
          child: MaterialApp.router(
            localizationsDelegates:
                quill.FlutterQuillLocalizations.localizationsDelegates,
            supportedLocales: quill.FlutterQuillLocalizations.supportedLocales,
            locale: const Locale('zh'),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('导入卡片'));
      await tester.pumpAndSettle();
      expect(find.text('快捷导入'), findsOneWidget);

      await tester.tap(find.byTooltip('返回'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('新卡片'));
      await tester.pumpAndSettle();
      expect(find.text('新建卡片'), findsOneWidget);
      expect(find.byType(quill.QuillEditor), findsOneWidget);
    });
  });

  group('Review flow', () {
    testWidgets('flips card, rates it, and completes queue', (tester) async {
      final repo = MockReviewRepository();
      when(
        () => repo.getDueCards(deckId: null),
      ).thenAnswer((_) async => [ReviewCard.fromJson(reviewCardJson())]);
      when(
        () => repo.rateCard('card-1', 'FAMILIAR'),
      ).thenAnswer((_) async => ReviewResult.fromJson(reviewResultJson()));
      final router = GoRouter(
        initialLocation: '/review',
        routes: [
          GoRoute(path: '/review', builder: (_, _) => const ReviewPage()),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: reviewOverrides(repo, const ReviewSessionState()),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('正面'), findsWidgets);

      await tester.tap(find.byType(ReviewFlipCard));
      await tester.pumpAndSettle();
      expect(find.text('本次回忆'), findsOneWidget);

      await tester.tap(find.text('熟悉'));
      await tester.pumpAndSettle();

      expect(find.text('今日复习完成'), findsOneWidget);
    });
  });

  group('Card editor page', () {
    testWidgets('switches between front and back without losing drafts', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates:
                quill.FlutterQuillLocalizations.localizationsDelegates,
            supportedLocales: quill.FlutterQuillLocalizations.supportedLocales,
            locale: const Locale('zh'),
            home: const CardEditorPage(
              args: CardEditorArgs(
                deckId: 'deck-1',
                initialFront: '正面草稿',
                initialBack: '反面草稿',
                localOnly: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(quill.QuillEditor), findsOneWidget);
      final frontEditor = tester.widget<quill.QuillEditor>(
        find.byType(quill.QuillEditor),
      );
      expect(frontEditor.controller.document.toPlainText(), contains('正面草稿'));

      await tester.tap(find.text('反面'));
      await tester.pumpAndSettle();

      expect(find.byType(quill.QuillEditor), findsOneWidget);
      final backEditor = tester.widget<quill.QuillEditor>(
        find.byType(quill.QuillEditor),
      );
      expect(backEditor.controller.document.toPlainText(), contains('反面草稿'));

      await tester.tap(find.text('正面'));
      await tester.pumpAndSettle();

      expect(find.byType(quill.QuillEditor), findsOneWidget);
      final frontAgain = tester.widget<quill.QuillEditor>(
        find.byType(quill.QuillEditor),
      );
      expect(frontAgain.controller.document.toPlainText(), contains('正面草稿'));
    });

    testWidgets('toolbar applies formatting and supports undo and redo', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates:
                quill.FlutterQuillLocalizations.localizationsDelegates,
            supportedLocales: quill.FlutterQuillLocalizations.supportedLocales,
            locale: const Locale('zh'),
            home: const CardEditorPage(
              args: CardEditorArgs(deckId: 'deck-1', localOnly: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final editor = tester.widget<quill.QuillEditor>(
        find.byType(quill.QuillEditor),
      );
      final controller = editor.controller;
      controller.document.insert(0, 'hello');
      controller.updateSelection(
        const TextSelection(baseOffset: 0, extentOffset: 5),
        quill.ChangeSource.local,
      );
      await tester.pump();

      await tester.tap(find.byTooltip('加粗'));
      await tester.pump();
      expect(
        controller.getSelectionStyle().attributes.containsKey('bold'),
        isTrue,
      );

      await tester.tap(find.byTooltip('撤销'));
      await tester.pump();
      expect(
        controller.getSelectionStyle().attributes.containsKey('bold'),
        isFalse,
      );

      await tester.tap(find.byTooltip('重做'));
      await tester.pump();
      expect(
        controller.getSelectionStyle().attributes.containsKey('bold'),
        isTrue,
      );
    });

    testWidgets('toolbar inserts latex through dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates:
                quill.FlutterQuillLocalizations.localizationsDelegates,
            supportedLocales: quill.FlutterQuillLocalizations.supportedLocales,
            locale: const Locale('zh'),
            home: const CardEditorPage(
              args: CardEditorArgs(deckId: 'deck-1', localOnly: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final controller = tester
          .widget<quill.QuillEditor>(find.byType(quill.QuillEditor))
          .controller;
      await tester.ensureVisible(find.byTooltip('插入公式'));
      await tester.tap(find.byTooltip('插入公式'));
      await tester.pumpAndSettle();

      expect(find.text('插入 LaTeX 公式'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'x^2');
      await tester.tap(find.text('插入'));
      await tester.pumpAndSettle();
      expect(controller.document.toDelta().toString(), contains('x^2'));
    });

    testWidgets('toolbar inserts code embed through dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates:
                quill.FlutterQuillLocalizations.localizationsDelegates,
            supportedLocales: quill.FlutterQuillLocalizations.supportedLocales,
            locale: const Locale('zh'),
            home: const CardEditorPage(
              args: CardEditorArgs(deckId: 'deck-1', localOnly: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final controller = tester
          .widget<quill.QuillEditor>(find.byType(quill.QuillEditor))
          .controller;
      await tester.ensureVisible(find.byTooltip('插入代码'));
      await tester.tap(find.byTooltip('插入代码'));
      await tester.pumpAndSettle();

      expect(find.text('插入代码块'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(1), 'void main() {}');
      await tester.tap(find.text('插入'));
      await tester.pumpAndSettle();
      expect(
        controller.document.toDelta().toString(),
        contains('void main() {}'),
      );
    });
  });

  group('Import page', () {
    testWidgets('previews and deletes imported rows', (tester) async {
      final repo = MockCardRepository();
      const content = '[{"front":"正面","back":"反面"},{"front":"","back":"反面"}]';
      when(
        () => repo.previewCardImport('deck-1', content),
      ).thenAnswer((_) async => importPreviewJson());

      await tester.pumpWidget(
        MaterialApp(
          home: CardImportPage(deckId: 'deck-1', repository: repo),
        ),
      );

      await tester.enterText(find.byType(TextField), content);
      await tester.tap(find.text('解析并预览'));
      await tester.pumpAndSettle();

      expect(find.text('导入预览'), findsOneWidget);
      expect(find.text('正面'), findsOneWidget);
      expect(find.textContaining('正面内容不能为空'), findsOneWidget);

      await tester.tap(find.byTooltip('删除').last);
      await tester.pumpAndSettle();
      expect(find.text('导入 1 张卡片'), findsOneWidget);
    });

    testWidgets('renders below status bar on a narrow phone', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(padding: const EdgeInsets.only(top: 24, bottom: 24)),
            child: child!,
          ),
          home: CardImportPage(deckId: 'deck-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('快捷导入'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(tester.getTopLeft(find.text('快捷导入')).dy, greaterThanOrEqualTo(24));
    });
  });

  group('Stats and settings', () {
    testWidgets('stats page renders overview and trend', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = MockStatsRepository();
      when(
        () => repo.getOverview(),
      ).thenAnswer((_) async => OverviewStats.fromJson(overviewStatsJson()));

      await tester.pumpWidget(
        ProviderScope(
          overrides: statsOverrides(repo),
          child: const MaterialApp(home: StatsPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('学习统计'), findsOneWidget);
      expect(find.text('总卡片'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('settings page renders account and refresh time', (
      tester,
    ) async {
      final authRepo = MockAuthRepository();
      when(() => authRepo.isLoggedIn()).thenAnswer((_) async => false);
      final settingsRepo = MockSettingsRepository();
      when(
        () => settingsRepo.getSettings(),
      ).thenAnswer((_) async => {'email': 'a@b.c', 'refresh_time': '04:00:00'});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...authOverrides(authRepo),
            ...settingsOverrides(settingsRepo),
          ],
          child: const MaterialApp(home: SettingsPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('设置'), findsWidgets);
      expect(find.text('a@b.c'), findsOneWidget);
      expect(find.text('04:00'), findsOneWidget);
    });
  });

  group('Shared widgets', () {
    testWidgets('metric tile renders label and value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MetricTile(label: '今日', value: '3', icon: Icons.today),
          ),
        ),
      );

      expect(find.text('今日'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets(
      'adaptive scaffold respects system insets and keeps nav glass blur',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(padding: const EdgeInsets.only(top: 24, bottom: 24)),
              child: child!,
            ),
            home: const AdaptiveAppScaffold(
              body: SizedBox(
                key: Key('scaffold-body'),
                width: 100,
                height: 100,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(BackdropFilter), findsNWidgets(2));
        expect(
          tester.getTopLeft(find.byKey(const Key('scaffold-body'))).dy,
          greaterThanOrEqualTo(24),
        );
        final navRect = tester.getRect(find.text('今日'));
        expect(navRect.left, greaterThan(0));
        expect(navRect.right, lessThan(390));
        expect(navRect.bottom, lessThanOrEqualTo(820));
      },
    );

    testWidgets('review flip card renders front and flipped back', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReviewFlipCard(
              flipped: true,
              onTap: () {},
              front: const Text('正面'),
              back: const Text('反面'),
              semanticsLabel: '闪卡',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('反面'), findsOneWidget);
    });
  });
}

dynamic loginResponse(String email) {
  return LoginResponse.fromJson({
    'token': 'token',
    'user': {'id': 'u1', 'email': email},
  });
}

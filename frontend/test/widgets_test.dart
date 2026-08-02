import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:karisreview/auth/models/login_request.dart';
import 'package:karisreview/auth/models/login_response.dart';
import 'package:karisreview/auth/pages/login_page.dart';
import 'package:karisreview/auth/pages/register_page.dart';
import 'package:karisreview/card/pages/card_list_page.dart';
import 'package:karisreview/card/widgets/card_import_sheet.dart';
import 'package:karisreview/deck/models/deck.dart';
import 'package:karisreview/deck/pages/deck_list_page.dart';
import 'package:karisreview/home/pages/home_page.dart';
import 'package:karisreview/review/models/review_card.dart';
import 'package:karisreview/review/pages/review_page.dart';
import 'package:karisreview/review/providers/review_provider.dart';
import 'package:karisreview/review/widgets/review_flip_card.dart';
import 'package:karisreview/review/pages/start_flow_page.dart';
import 'package:karisreview/settings/pages/settings_page.dart';
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

  group('Import sheet', () {
    testWidgets('previews and deletes imported rows', (tester) async {
      final repo = MockCardRepository();
      const content = '[{"front":"正面","back":"反面"},{"front":"","back":"反面"}]';
      when(
        () => repo.previewCardImport('deck-1', content),
      ).thenAnswer((_) async => importPreviewJson());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardImportSheet(deckId: 'deck-1', repository: repo),
          ),
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

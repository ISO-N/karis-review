import 'dart:convert';
import 'package:karisreview/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:karisreview/auth/models/login_request.dart';
import 'package:karisreview/auth/models/login_response.dart';
import 'package:karisreview/auth/models/register_request.dart';
import 'package:karisreview/auth/pages/forgot_password_page.dart';
import 'package:karisreview/auth/pages/login_page.dart';
import 'package:karisreview/auth/pages/register_page.dart';
import 'package:karisreview/card/models/card_import.dart';
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
import 'package:karisreview/shared/widgets/app_feedback.dart';
import 'package:karisreview/shared/widgets/metric_tile.dart';
import 'package:karisreview/stats/pages/stats_page.dart';
import 'package:karisreview/stats/models/stats.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_helpers.dart';

class _StaticReviewNotifier extends ReviewNotifier {
  _StaticReviewNotifier(super.repository, ReviewSessionState initial) {
    state = initial;
  }

  @override
  Future<void> loadQueue({
    required String mode,
    String? deckId,
    int limit = 10,
  }) async {}
}

Future<void> _pumpHome(WidgetTester tester, MockStatsRepository statsRepo) async {
  final authRepo = MockAuthRepository();
  when(() => authRepo.isLoggedIn()).thenAnswer((_) async => false);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...authOverrides(authRepo),
        ...statsOverrides(statsRepo),
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
        home: HomePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('zh_CN');
    registerFallbackValue(
      LoginRequest(email: 'fallback@example.com', password: 'fallback'),
    );
    registerFallbackValue(
      RegisterRequest(
        email: 'fallback@example.com',
        password: 'fallback',
        verificationCode: '123456',
      ),
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
          child: MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              KarisReviewLocalizations.delegate,
            ],
            supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
            home: LoginPage()),
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
          child: MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              KarisReviewLocalizations.delegate,
            ],
            supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
            home: RegisterPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('邀请码'), findsNothing);

      await tester.enterText(find.byType(TextFormField).at(0), 'a@b.c');
      await tester.enterText(find.byType(TextFormField).at(1), 'secret');
      await tester.enterText(find.byType(TextFormField).at(2), 'secret');
      await tester.enterText(find.byType(TextFormField).at(3), '123456');
      await tester.tap(find.text('注册'));
      await tester.pumpAndSettle();

      final captured = verify(() => repo.register(captureAny())).captured;
      final request = captured.single as RegisterRequest;
      expect(request.inviteCode, isNull);
      expect(request.verificationCode, '123456');
    });

    testWidgets('register requires and sends invite code when enabled', (
      tester,
    ) async {
      final repo = MockAuthRepository();
      when(() => repo.isLoggedIn()).thenAnswer((_) async => false);
      when(
        () => repo.register(any()),
      ).thenAnswer((_) async => loginResponse('a@b.c'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: authOverrides(repo, inviteCodeRequired: true),
          child: MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              KarisReviewLocalizations.delegate,
            ],
            supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
            home: RegisterPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('邀请码'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'a@b.c');
      await tester.enterText(find.byType(TextFormField).at(1), 'secret');
      await tester.enterText(find.byType(TextFormField).at(2), 'secret');
      await tester.enterText(find.byType(TextFormField).at(4), '123456');
      await tester.ensureVisible(find.text('注册'));
      await tester.tap(find.text('注册'));
      await tester.pump();

      expect(find.text('请输入邀请码'), findsOneWidget);
      verifyNever(() => repo.register(any()));

      await tester.enterText(find.byType(TextFormField).at(3), ' code ');
      await tester.ensureVisible(find.text('注册'));
      await tester.tap(find.text('注册'));
      await tester.pumpAndSettle();

      final captured = verify(() => repo.register(captureAny())).captured;
      final request = captured.single as RegisterRequest;
      expect(request.inviteCode, 'code');
    });

    testWidgets('forgot password sends code and resets', (tester) async {
      final repo = MockAuthRepository();
      when(() => repo.isLoggedIn()).thenAnswer((_) async => false);
      when(() => repo.sendResetCode(any())).thenAnswer((_) async {});
      when(() => repo.resetPassword(any(), any(), any())).thenAnswer((_) async {});

      final router = GoRouter(
        initialLocation: '/forgot-password',
        routes: [
          GoRoute(
            path: '/forgot-password',
            builder: (_, _) => const ForgotPasswordPage(),
          ),
          GoRoute(path: '/login', builder: (_, _) => const Scaffold()),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: authOverrides(repo),
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              KarisReviewLocalizations.delegate,
            ],
            supportedLocales: KarisReviewLocalizations.supportedLocales,
            locale: const Locale('zh'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'a@b.c');
      await tester.ensureVisible(find.text('获取验证码'));
      await tester.tap(find.text('获取验证码'));
      await tester.pumpAndSettle();

      verify(() => repo.sendResetCode('a@b.c')).called(1);
      expect(find.text('验证码已发送，请查收邮件'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(1), '123456');
      await tester.enterText(find.byType(TextFormField).at(2), 'new-password');
      await tester.ensureVisible(find.text('重置密码'));
      await tester.tap(find.text('重置密码'));
      await tester.pumpAndSettle();

      verify(() => repo.resetPassword('a@b.c', '123456', 'new-password')).called(1);
    });
  });

  group('Dashboard pages', () {
    testWidgets('home renders today and memory scale', (tester) async {
      final statsRepo = MockStatsRepository();
      when(
        () => statsRepo.getOverview(),
      ).thenAnswer((_) async => OverviewStats.fromJson(overviewStatsJson()));
      await _pumpHome(tester, statsRepo);

      expect(find.text('今日待复习'), findsOneWidget);
      expect(find.text('记忆刻度'), findsOneWidget);
      expect(find.text('3 张待复习'), findsOneWidget);
      expect(find.textContaining('日语 N5'), findsNothing);
    });

    testWidgets('home memory scale shows learning count when no due', (
      tester,
    ) async {
      final statsRepo = MockStatsRepository();
      when(
        () => statsRepo.getOverview(),
      ).thenAnswer(
        (_) async => OverviewStats.fromJson(
          overviewStatsJson(dueToday: 0, newCards: 4),
        ),
      );
      await _pumpHome(tester, statsRepo);

      expect(find.text('4 张待学习'), findsOneWidget);
    });

    testWidgets('home memory scale prompts when no cards remain', (
      tester,
    ) async {
      final statsRepo = MockStatsRepository();
      when(
        () => statsRepo.getOverview(),
      ).thenAnswer(
        (_) async => OverviewStats.fromJson(
          overviewStatsJson(dueToday: 0, newCards: 0),
        ),
      );
      await _pumpHome(tester, statsRepo);

      expect(find.text('今天没有新任务，补充新卡或休息一天'), findsOneWidget);
    });

    testWidgets('deck list renders rows and empty state', (tester) async {
      final repo = MockDeckRepository();
      when(
        () => repo.getDecks(),
      ).thenAnswer((_) async => [Deck.fromJson(deckJson())]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: deckOverrides(repo),
          child: MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              KarisReviewLocalizations.delegate,
            ],
            supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
            home: DeckListPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('日语 N5'), findsOneWidget);
      expect(find.text('2 张 · 待复习 1'), findsOneWidget);
    });

    testWidgets('deck list filters rows by search query', (tester) async {
      final repo = MockDeckRepository();
      when(
        () => repo.getDecks(),
      ).thenAnswer(
        (_) async => [
          Deck.fromJson(deckJson(name: '日语 N5')),
          Deck.fromJson(deckJson(id: 'deck-2', name: '英语口语')),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: deckOverrides(repo),
          child: MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              KarisReviewLocalizations.delegate,
            ],
            supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
            home: DeckListPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('英语口语'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '英语');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('英语口语'), findsOneWidget);
      expect(find.text('日语 N5'), findsNothing);
      expect(find.text('搜索到 1 个'), findsOneWidget);

      await tester.tap(find.byTooltip('清除搜索'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.text('日语 N5'), findsOneWidget);
      expect(find.text('英语口语'), findsOneWidget);
    });
    testWidgets('deck list opens styled action sheet', (tester) async {
      final repo = MockDeckRepository();
      when(
        () => repo.getDecks(),
      ).thenAnswer((_) async => [Deck.fromJson(deckJson())]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: deckOverrides(repo),
          child: MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              KarisReviewLocalizations.delegate,
            ],
            supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
            home: DeckListPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('卡组操作'));
      await tester.pumpAndSettle();

      expect(find.text('重命名'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);
    });

    testWidgets('deck list renders empty state', (tester) async {
      final emptyRepo = MockDeckRepository();
      when(() => emptyRepo.getDecks()).thenAnswer((_) async => []);
      await tester.pumpWidget(
        ProviderScope(
          overrides: deckOverrides(emptyRepo),
          child: MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              KarisReviewLocalizations.delegate,
            ],
            supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
            home: DeckListPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('还没有卡组'), findsOneWidget);
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
          child: MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              KarisReviewLocalizations.delegate,
            ],
            supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
            home: StartFlowPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('开始复习'), findsWidgets);
      await tester.tap(find.text('学习新卡'));
      await tester.pumpAndSettle();
      expect(find.text('开始学习'), findsWidgets);
    });

    testWidgets('start flow lists only decks with cards in current mode', (
      tester,
    ) async {
      final repo = MockDeckRepository();
      when(
        () => repo.getDecks(),
      ).thenAnswer(
        (_) async => [
          Deck.fromJson(
            deckJson(id: 'due-deck', name: '待复习卡组', dueCount: 3, newCount: 0),
          ),
          Deck.fromJson(
            deckJson(id: 'new-deck', name: '新卡卡组', dueCount: 0, newCount: 2),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: deckOverrides(repo),
          child: MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              KarisReviewLocalizations.delegate,
            ],
            supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
            home: StartFlowPage()),
        ),
      );
      await tester.pumpAndSettle();

      // 复习模式：只有待复习卡组可选。
      expect(find.text('待复习卡组'), findsOneWidget);
      expect(find.text('新卡卡组'), findsNothing);

      await tester.tap(find.text('学习新卡'));
      await tester.pumpAndSettle();
      expect(find.text('新卡卡组'), findsOneWidget);
      expect(find.text('待复习卡组'), findsNothing);
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
      when(
        () => cardRepo.getDeckCards('deck-1', size: 500, filter: 'new'),
      ).thenAnswer(
        (_) async => {
          'content': [cardJson(id: 'card-new', front: '新卡内容')],
        },
      );
      final statsRepo = MockStatsRepository();
      when(
        () => statsRepo.getOverview(),
      ).thenAnswer((_) async => OverviewStats.fromJson(overviewStatsJson()));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [...cardOverrides(cardRepo), ...statsOverrides(statsRepo)],
          child: MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              KarisReviewLocalizations.delegate,
            ],
            supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
            home: CardListPage(deckId: 'deck-1')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('日语 N5'), findsOneWidget);
      expect(find.text('正面内容'), findsOneWidget);

      await tester.tap(find.text('新卡').first);
      await tester.pumpAndSettle();
      expect(find.text('新卡内容'), findsOneWidget);

      await tester.tap(find.text('待复习'));
      await tester.pumpAndSettle();
      expect(find.text('全部'), findsOneWidget);
    });

    testWidgets('card list shows status and formatted next review date', (
      tester,
    ) async {
      final now = DateTime.now();
      final sameYear = '${now.year}-12-25';
      final nextYear = '${now.year + 1}-01-05';
      final cardRepo = MockCardRepository();
      when(
        () => cardRepo.getDeckCards('deck-1', size: 500, filter: 'all'),
      ).thenAnswer(
        (_) async => {
          'content': [
            cardJson(id: 'new-card', front: '新卡正面'),
            cardJson(
              id: 'review-card',
              front: '复习正面',
              stage: 3,
              nextReviewDate: sameYear,
            ),
            cardJson(
              id: 'mastered-card',
              front: '掌握正面',
              stage: 8,
              nextReviewDate: nextYear,
            ),
            cardJson(
              id: 'learning-card',
              front: '重学正面',
              learning: true,
              consecutiveFamiliar: 2,
            ),
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
          child: MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              KarisReviewLocalizations.delegate,
            ],
            supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
            home: CardListPage(deckId: 'deck-1')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('新卡'), findsWidgets);
      expect(find.text('复习'), findsOneWidget);
      expect(find.text('掌握'), findsOneWidget);
      expect(find.text('重学 2/5'), findsOneWidget);
      expect(find.text('12月25日'), findsOneWidget);
      expect(find.text('${now.year + 1}年1月5日'), findsOneWidget);
    });

    testWidgets('card list selection bar uses compact labels', (tester) async {
      final cardRepo = MockCardRepository();
      when(
        () => cardRepo.getDeckCards('deck-1', size: 500, filter: 'all'),
      ).thenAnswer(
        (_) async => {
          'content': [
            cardJson(id: 'card-0', front: '卡片 0'),
            cardJson(id: 'card-1', front: '卡片 1'),
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
          child: MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              KarisReviewLocalizations.delegate,
            ],
            supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
            home: CardListPage(deckId: 'deck-1')),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('多选'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('卡片 0'));
      await tester.pumpAndSettle();

      expect(find.text('全选'), findsOneWidget);
      expect(find.text('删除所选（1）'), findsOneWidget);
      expect(tester.getSize(find.text('全选')).height, lessThanOrEqualTo(24));
      expect(
        tester.getSize(find.text('删除所选（1）')).height,
        lessThanOrEqualTo(24),
      );
    });
    testWidgets('card list debounces search and renders results', (
      tester,
    ) async {
      final cardRepo = MockCardRepository();
      when(
        () => cardRepo.getDeckCards('deck-1', size: 500, filter: 'all'),
      ).thenAnswer(
        (_) async => {
          'content': [cardJson(id: 'base', front: '基础卡片')],
        },
      );
      when(
        () => cardRepo.getDeckCards(
          'deck-1',
          size: 500,
          filter: 'all',
          query: '词',
        ),
      ).thenAnswer(
        (_) async => {
          'content': [cardJson(id: 'hit', front: '命中词')],
        },
      );
      final statsRepo = MockStatsRepository();
      when(
        () => statsRepo.getOverview(),
      ).thenAnswer((_) async => OverviewStats.fromJson(overviewStatsJson()));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [...cardOverrides(cardRepo), ...statsOverrides(statsRepo)],
          child: MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              KarisReviewLocalizations.delegate,
            ],
            supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
            home: CardListPage(deckId: 'deck-1')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('基础卡片'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '词');
      await tester.pump(const Duration(milliseconds: 200));
      verifyNever(
        () => cardRepo.getDeckCards(
          'deck-1',
          size: 500,
          filter: 'all',
          query: '词',
        ),
      );

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      verify(
        () => cardRepo.getDeckCards(
          'deck-1',
          size: 500,
          filter: 'all',
          query: '词',
        ),
      ).called(1);
      expect(find.text('命中词'), findsOneWidget);

      await tester.tap(find.byTooltip('清除搜索'));
      await tester.pumpAndSettle();
      expect(find.text('基础卡片'), findsOneWidget);
    });

    testWidgets('card list supports multi-select batch delete', (tester) async {
      final cardRepo = MockCardRepository();
      when(
        () => cardRepo.getDeckCards('deck-1', size: 500, filter: 'all'),
      ).thenAnswer(
        (_) async => {
          'content': [
            cardJson(id: 'card-0', front: '卡片 0'),
            cardJson(id: 'card-1', front: '卡片 1'),
          ],
        },
      );
      when(
        () => cardRepo.batchDeleteCards(['card-0', 'card-1']),
      ).thenAnswer((_) async {});
      final statsRepo = MockStatsRepository();
      when(
        () => statsRepo.getOverview(),
      ).thenAnswer((_) async => OverviewStats.fromJson(overviewStatsJson()));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [...cardOverrides(cardRepo), ...statsOverrides(statsRepo)],
          child: MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              KarisReviewLocalizations.delegate,
            ],
            supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
            home: CardListPage(deckId: 'deck-1')),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('多选'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('卡片 0'));
      await tester.tap(find.text('卡片 1'));
      await tester.pumpAndSettle();

      expect(find.text('删除所选（2）'), findsOneWidget);
      await tester.tap(find.text('删除所选（2）'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();

      verify(() => cardRepo.batchDeleteCards(['card-0', 'card-1'])).called(1);
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
          child: MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              KarisReviewLocalizations.delegate,
            ],
            supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
            home: CardListPage(deckId: 'deck-1')),
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
                [
                ...quill.FlutterQuillLocalizations.localizationsDelegates,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                KarisReviewLocalizations.delegate,
            ],
            supportedLocales: KarisReviewLocalizations.supportedLocales,
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

    testWidgets('import completion offers undo action', (tester) async {
      const content =
          '[{"front":"正面","back":"反面"},{"front":"第二张","back":"反面二"}]';
      final cardRepo = MockCardRepository();
      when(
        () => cardRepo.getDeckCards('deck-1', size: 500, filter: 'all'),
      ).thenAnswer((_) async => {'content': []});
      when(
        () => cardRepo.previewCardImport('deck-1', content),
      ).thenAnswer((_) async => validImportPreviewJson());
      when(
        () => cardRepo.importCards('deck-1', any()),
      ).thenAnswer((_) async => CardImportResult.fromJson(importResultJson()));
      when(
        () => cardRepo.batchDeleteCards(['card-1', 'card-2']),
      ).thenAnswer((_) async {});
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
            path: '/decks/:deckId/cards/import',
            builder: (_, state) => CardImportPage(
              deckId: state.pathParameters['deckId']!,
              repository: cardRepo,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [...cardOverrides(cardRepo), ...statsOverrides(statsRepo)],
          child: MaterialApp.router(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              KarisReviewLocalizations.delegate,
            ],
            supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('导入卡片'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), content);
      await tester.ensureVisible(find.text('解析并预览'));
      await tester.tap(find.text('解析并预览'));
      await tester.pumpAndSettle();
      expect(find.text('导入预览'), findsOneWidget);
      await tester.tap(find.text('导入 2 张卡片'));
      await tester.pumpAndSettle();

      expect(find.text('已导入 2 张卡片'), findsOneWidget);
      expect(find.text('撤销导入'), findsOneWidget);
      await tester.tap(find.text('撤销导入'));
      await tester.pumpAndSettle();

      expect(find.text('已撤销导入'), findsOneWidget);
      verify(() => cardRepo.batchDeleteCards(['card-1', 'card-2'])).called(1);
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
          child: MaterialApp.router(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              KarisReviewLocalizations.delegate,
            ],
            supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        ProviderScope(
          overrides: reviewOverrides(repo, const ReviewSessionState()),
          child: MaterialApp.router(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              KarisReviewLocalizations.delegate,
            ],
            supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('正面'), findsWidgets);
      expect(find.text('忘记'), findsOneWidget);
      expect(find.text('熟悉'), findsOneWidget);

      await tester.tap(find.text('熟悉'));
      await tester.pumpAndSettle();
      expect(find.text('正面'), findsWidgets);

      await tester.tap(find.byType(ReviewFlipCard));
      await tester.pumpAndSettle();

      await tester.tap(find.text('熟悉'));
      await tester.pumpAndSettle();

      expect(find.text('今日复习完成'), findsOneWidget);
    });

    testWidgets('rating feedback shows in the status chip', (tester) async {
      final repo = MockReviewRepository();
      when(
        () => repo.getDueCards(deckId: null),
      ).thenAnswer(
        (_) async => [
          ReviewCard.fromJson(reviewCardJson(id: 'card-1')),
          ReviewCard.fromJson(reviewCardJson(id: 'card-2')),
        ],
      );
      when(
        () => repo.rateCard(any(), 'FAMILIAR'),
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
          child: MaterialApp.router(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              KarisReviewLocalizations.delegate,
            ],
            supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ReviewFlipCard));
      await tester.pumpAndSettle();
      await tester.tap(find.text('熟悉'));
      await tester.pump();

      expect(find.text('已评分 熟悉 · 下次 1 天'), findsOneWidget);
      expect(find.byType(KarisFeedbackBar), findsNothing);
    });

    testWidgets('mobile review fills card and returns to front from answer', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = MockReviewRepository();
      when(
        () => repo.getDueCards(deckId: null),
      ).thenAnswer((_) async => [ReviewCard.fromJson(reviewCardJson())]);
      final router = GoRouter(
        initialLocation: '/review',
        routes: [
          GoRoute(path: '/review', builder: (_, _) => const ReviewPage()),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: reviewOverrides(repo, const ReviewSessionState()),
          child: MaterialApp.router(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              KarisReviewLocalizations.delegate,
            ],
            supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('忘记'), findsOneWidget);
      expect(find.text('模糊'), findsOneWidget);
      expect(find.text('熟悉'), findsOneWidget);

      await tester.tap(find.text('忘记'));
      await tester.pumpAndSettle();
      expect(find.text('正面'), findsWidgets);

      await tester.tap(find.byType(ReviewFlipCard));
      await tester.pumpAndSettle();
      expect(find.text('忘记'), findsOneWidget);

      await tester.tap(find.byType(ReviewFlipCard));
      await tester.pumpAndSettle();
      expect(find.text('忘记'), findsOneWidget);
      expect(find.text('正面'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
    testWidgets('completion view uses server session total', (tester) async {
      final repo = MockReviewRepository();
      final state = ReviewSessionState(
        mode: 'new',
        cards: [
          for (var i = 0; i < 25; i++)
            ReviewCard.fromJson(reviewCardJson(id: 'card-$i')),
        ],
        currentIndex: 25,
        reviewedCount: 25,
        totalCount: 10,
        serverTotal: 25,
        hasMore: false,
      );
      final router = GoRouter(
        initialLocation: '/review?mode=new',
        routes: [
          GoRoute(path: '/review', builder: (_, _) => const ReviewPage()),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reviewProvider.overrideWith(
              (ref) => _StaticReviewNotifier(repo, state),
            ),
          ],
          child: MaterialApp.router(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              KarisReviewLocalizations.delegate,
            ],
            supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('本轮学习完成'), findsOneWidget);
      expect(find.text('本次 25 张 · 已学习 25'), findsOneWidget);
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
                [
                ...quill.FlutterQuillLocalizations.localizationsDelegates,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                KarisReviewLocalizations.delegate,
              ],
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
                [
                ...quill.FlutterQuillLocalizations.localizationsDelegates,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                KarisReviewLocalizations.delegate,
              ],
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
                [
                ...quill.FlutterQuillLocalizations.localizationsDelegates,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                KarisReviewLocalizations.delegate,
              ],
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
                [
                ...quill.FlutterQuillLocalizations.localizationsDelegates,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                KarisReviewLocalizations.delegate,
              ],
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
    testWidgets('JSON input uses the normal keyboard (no suggestions suppressed)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            KarisReviewLocalizations.delegate,
          ],
          supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: CardImportPage(deckId: 'deck-1'),
        ),
      );
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.keyboardType, TextInputType.multiline);
      // 国产 ROM 会把"无建议输入"误判为敏感字段强制弹安全键盘，须保持默认（允许建议/纠正）
      expect(field.autocorrect, isNot(false));
      expect(field.enableSuggestions, isNot(false));
    });

    testWidgets('previews and deletes imported rows', (tester) async {
      final repo = MockCardRepository();
      const content = '[{"front":"正面","back":"反面"},{"front":"","back":"反面"}]';
      when(
        () => repo.previewCardImport('deck-1', content),
      ).thenAnswer((_) async => importPreviewJson());

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            KarisReviewLocalizations.delegate,
          ],
          supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: CardImportPage(deckId: 'deck-1', repository: repo),
        ),
      );

      await tester.enterText(find.byType(TextField), content);
      await tester.ensureVisible(find.text('解析并预览'));
      await tester.tap(find.text('解析并预览'));
      await tester.pumpAndSettle();

      expect(find.text('导入预览'), findsOneWidget);
      expect(find.text('正面'), findsOneWidget);
      expect(find.textContaining('正面内容不能为空'), findsOneWidget);

      await tester.tap(find.byTooltip('删除').last);
      await tester.pumpAndSettle();
      expect(find.text('导入 1 张卡片'), findsOneWidget);
    });

    testWidgets('shows JSON format guide and copies example', (tester) async {
      final copiedTexts = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            final arguments = call.arguments as Map;
            copiedTexts.add(arguments['text'] as String);
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            KarisReviewLocalizations.delegate,
          ],
          supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: CardImportPage(deckId: 'deck-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('JSON 格式'), findsOneWidget);
      expect(find.textContaining('间隔重复是什么？'), findsOneWidget);
      expect(find.text('格式要点'), findsOneWidget);

      await tester.ensureVisible(find.text('复制示例'));
      await tester.tap(find.text('复制示例'));
      await tester.pumpAndSettle();

      expect(copiedTexts, hasLength(1));
      final decoded = jsonDecode(copiedTexts.single) as List<dynamic>;
      final first = decoded.first as Map<String, dynamic>;
      expect(first['front'], '间隔重复是什么？');
      expect(first['back'], '按遗忘曲线在合适时间安排复习');
      expect(find.text('示例 JSON 已复制'), findsOneWidget);
    });

    testWidgets('renders below status bar on a narrow phone', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            KarisReviewLocalizations.delegate,
          ],
          supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
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
          child: MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              KarisReviewLocalizations.delegate,
            ],
            supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
            home: StatsPage()),
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
          child: MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              KarisReviewLocalizations.delegate,
            ],
            supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
            home: SettingsPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('设置'), findsWidgets);
      expect(find.text('a@b.c'), findsOneWidget);
      expect(find.text('04:00'), findsOneWidget);
    });

    testWidgets('settings change password dialog validates and submits', (
      tester,
    ) async {
      final authRepo = MockAuthRepository();
      when(() => authRepo.isLoggedIn()).thenAnswer((_) async => false);
      when(() => authRepo.changePassword(any(), any())).thenAnswer((_) async {});
      when(() => authRepo.logout()).thenAnswer((_) async {});
      final settingsRepo = MockSettingsRepository();
      when(
        () => settingsRepo.getSettings(),
      ).thenAnswer((_) async => {'email': 'a@b.c', 'refresh_time': '04:00:00'});

      // 修改成功后跳 /login，需要真实 GoRouter 环境
      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
          GoRoute(path: '/login', builder: (_, _) => const Scaffold()),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...authOverrides(authRepo),
            ...settingsOverrides(settingsRepo),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              KarisReviewLocalizations.delegate,
            ],
            supportedLocales: KarisReviewLocalizations.supportedLocales,
            locale: const Locale('zh'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('修改密码'));
      await tester.pumpAndSettle();
      expect(find.text('当前密码'), findsOneWidget);

      // 新密码过短 → 前端校验
      await tester.enterText(find.byType(TextFormField).at(0), 'old-password');
      await tester.enterText(find.byType(TextFormField).at(1), '123');
      await tester.enterText(find.byType(TextFormField).at(2), '123');
      await tester.tap(find.text('确认修改'));
      await tester.pumpAndSettle();
      expect(find.text('新密码至少 6 位'), findsOneWidget);

      // 两次密码不一致 → 前端校验
      await tester.enterText(find.byType(TextFormField).at(1), 'new-password');
      await tester.enterText(find.byType(TextFormField).at(2), 'different');
      await tester.tap(find.text('确认修改'));
      await tester.pumpAndSettle();
      expect(find.text('两次输入的密码不一致'), findsOneWidget);

      // 合法提交 → 调用 changePassword 并跳转登录页
      await tester.enterText(find.byType(TextFormField).at(2), 'new-password');
      await tester.tap(find.text('确认修改'));
      await tester.pumpAndSettle();

      verify(() => authRepo.changePassword('old-password', 'new-password')).called(1);
      verify(() => authRepo.logout()).called(1);
    });
  });

  group('Shared widgets', () {
    testWidgets('metric tile keeps equal height on narrow screens', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            KarisReviewLocalizations.delegate,
          ],
          supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(
            body: Row(
              children: [
                Expanded(
                  child: MetricTile(label: '卡片', value: '1'),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: MetricTile(label: '今日待复习', value: '2'),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: MetricTile(label: '已掌握', value: '3'),
                ),
              ],
            ),
          ),
        ),
      );

      final heights = tester
          .widgetList<MetricTile>(find.byType(MetricTile))
          .map((widget) => tester.getSize(find.byWidget(widget)).height)
          .toSet();
      expect(heights, {96.0});
      expect(find.text('今日待复习'), findsOneWidget);
    });

    testWidgets(
      'adaptive scaffold respects system insets and keeps nav pill blur',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              KarisReviewLocalizations.delegate,
            ],
            supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
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

        // 全宽条带改为渐变遮罩（无模糊），仅药丸导航保留 BackdropFilter。
        expect(find.byType(BackdropFilter), findsOneWidget);
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
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            KarisReviewLocalizations.delegate,
          ],
          supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
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

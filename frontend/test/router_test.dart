import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:karisreview/app/router.dart';
import 'package:karisreview/auth/models/login_request.dart';
import 'package:karisreview/auth/pages/forgot_password_page.dart';
import 'package:karisreview/auth/pages/login_page.dart';import 'package:karisreview/home/pages/home_page.dart';
import 'package:karisreview/l10n/app_localizations.dart';
import 'package:karisreview/log/pages/logs_page.dart';
import 'package:karisreview/log/providers/logs_provider.dart';
import 'package:karisreview/log/repositories/logs_repository.dart';
import 'package:karisreview/offline/database/app_database.dart';
import 'package:karisreview/offline/offline_repository.dart';
import 'package:karisreview/shared/providers/data_refresh_provider.dart';
import 'package:karisreview/stats/models/stats.dart';
import 'package:karisreview/sync/repositories/sync_repository.dart';
import 'package:karisreview/sync/sync_service.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/test_helpers.dart';

late GoRouter capturedRouter;

Widget _harness({required bool authenticated}) {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final offline = OfflineRepository(db);
  final api = FakeApiClient();
  final sync = SyncService(SyncRepository(client: api), offline);
  final authRepo = MockAuthRepository();
  when(() => authRepo.isLoggedIn()).thenAnswer((_) async => authenticated);
  final statsRepo = MockStatsRepository();
  when(() => statsRepo.getOverview())
      .thenAnswer((_) async => OverviewStats.fromJson(overviewStatsJson()));
  final logsApi = FakeApiClient();
  logsApi.onGet = (_, _) async => okResponse({
        'content': [
          {
            'id': 'log-route',
            'level': 'INFO',
            'category': 'AUTH',
            'message': '登录成功',
            'details': null,
            'created_at': '2025-08-02T12:00:00Z',
          },
        ],
        'page': 0,
        'total_pages': 1,
      });

  return ProviderScope(
    overrides: [
      ...authOverrides(authRepo),
      ...statsOverrides(statsRepo),
      dataRefreshControllerProvider.overrideWithValue(
        DataRefreshController(sync, offline, () {}),
      ),
      logsProvider.overrideWith((ref) => LogsNotifier(LogsRepository(client: logsApi))),
    ],
    child: Consumer(
      builder: (context, ref, _) {
        capturedRouter = ref.watch(routerProvider);
        return MaterialApp.router(
          routerConfig: capturedRouter,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            KarisReviewLocalizations.delegate,
          ],
          supportedLocales: KarisReviewLocalizations.supportedLocales,
          locale: const Locale('zh'),
        );
      },
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(
      LoginRequest(email: 'fallback@example.com', password: 'fallback'),
    );
  });

  testWidgets('unauthenticated routes redirect to login', (tester) async {
    await tester.pumpWidget(_harness(authenticated: false));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('forgot password route is reachable when logged out', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(authenticated: false));
    await tester.pumpAndSettle();

    capturedRouter.go('/forgot-password');
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordPage), findsOneWidget);
  });

  testWidgets('authenticated home and logs route are reachable', (tester) async {
    await tester.pumpWidget(_harness(authenticated: true));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);

    capturedRouter.go('/settings/logs');
    await tester.pumpAndSettle();

    expect(find.byType(LogsPage), findsOneWidget);
    expect(find.text('登录成功'), findsOneWidget);
  });

  testWidgets('login failure keeps the router instance and typed input',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final offline = OfflineRepository(db);
    final api = FakeApiClient();
    final sync = SyncService(SyncRepository(client: api), offline);
    final authRepo = MockAuthRepository();
    when(() => authRepo.isLoggedIn()).thenAnswer((_) async => false);
    when(() => authRepo.login(any()))
        .thenThrow(apiError('邮箱或密码错误', statusCode: 401));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...authOverrides(authRepo),
          dataRefreshControllerProvider.overrideWithValue(
            DataRefreshController(sync, offline, () {}),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            capturedRouter = ref.watch(routerProvider);
            return MaterialApp.router(
              routerConfig: capturedRouter,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                KarisReviewLocalizations.delegate,
              ],
              supportedLocales: KarisReviewLocalizations.supportedLocales,
              locale: const Locale('zh'),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final routerBefore = capturedRouter;
    await tester.enterText(find.byType(TextFormField).first, 'user@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'wrong-password');
    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle();

    // 登录失败：router 实例不被重建，登录页输入内容保留
    expect(identical(routerBefore, capturedRouter), isTrue);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('邮箱或密码错误'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField).first).controller!.text,
      'user@example.com',
    );
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField).last).controller!.text,
      'wrong-password',
    );
  });
}

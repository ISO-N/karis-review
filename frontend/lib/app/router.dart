import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/pages/login_page.dart';
import '../auth/pages/forgot_password_page.dart';
import '../auth/providers/auth_provider.dart';
import '../shared/navigation/auto_refresh_observer.dart';
import '../shared/providers/data_refresh_provider.dart';
import '../shared/utils/motion.dart';
import '../auth/pages/register_page.dart';
import '../card/pages/card_editor_page.dart';
import '../card/pages/card_import_page.dart';
import '../card/pages/card_list_page.dart';
import '../deck/pages/deck_list_page.dart';
import '../home/pages/home_page.dart';
import '../review/pages/review_page.dart';
import '../review/pages/start_flow_page.dart';
import '../settings/pages/settings_page.dart';
import '../log/pages/logs_page.dart';
import '../stats/pages/stats_page.dart';

CustomTransitionPage<Object?> _fadeSlidePage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<Object?>(
    key: state.pageKey,
    transitionDuration: reducedDuration(
      context,
      const Duration(milliseconds: 260),
    ),
    reverseTransitionDuration: reducedDuration(
      context,
      const Duration(milliseconds: 220),
    ),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
    child: child,
  );
}

/// 未登录即可访问的公开路由（登录/注册/找回密码）。
bool _isAuthRoute(String matchedLocation) {
  return matchedLocation == '/login' ||
      matchedLocation == '/register' ||
      matchedLocation == '/forgot-password';
}

final routerProvider = Provider<GoRouter>((ref) {
  // 认证状态变化（含登录失败）时递增，仅触发 redirect 重评估，不重建 router 实例，
  // 避免登录页因 router 重建而丢失输入内容。
  final authRevision = ValueNotifier<int>(0);
  final autoRefreshObserver = AutoRefreshNavigatorObserver(
    onDataRouteChanged: () async {
      if (!ref.read(authProvider).isAuthenticated) return;
      await ref.read(dataRefreshControllerProvider).refreshFromServer();
    },
  );

  final router = GoRouter(
    initialLocation: '/home',
    refreshListenable: authRevision,
    observers: [autoRefreshObserver],
    redirect: (context, state) {
      final isLoggedIn = ref.read(authProvider).isAuthenticated;
      final isAuthRoute = _isAuthRoute(state.matchedLocation);

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _fadeSlidePage(context, state, const LoginPage()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) =>
            _fadeSlidePage(context, state, const RegisterPage()),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) =>
            _fadeSlidePage(context, state, const ForgotPasswordPage()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) =>
            _fadeSlidePage(context, state, const HomePage()),
      ),
      GoRoute(
        path: '/decks',
        pageBuilder: (context, state) =>
            _fadeSlidePage(context, state, const DeckListPage()),
      ),
      GoRoute(
        path: '/decks/:deckId/cards',
        pageBuilder: (context, state) {
          final filter = state.uri.queryParameters['filter'];
          return _fadeSlidePage(
            context,
            state,
            CardListPage(
              deckId: state.pathParameters['deckId']!,
              initialFilter:
                  filter == 'due' || filter == 'learning' || filter == 'new'
                  ? filter!
                  : 'all',
            ),
          );
        },
      ),
      GoRoute(
        path: '/decks/:deckId/cards/editor',
        pageBuilder: (context, state) {
          final deckId = state.pathParameters['deckId']!;
          final extra = state.extra;
          final args = extra is CardEditorArgs
              ? CardEditorArgs(
                  deckId: deckId,
                  cardId: extra.cardId,
                  initialFront: extra.initialFront,
                  initialBack: extra.initialBack,
                  title: extra.title,
                  localOnly: extra.localOnly,
                )
              : CardEditorArgs(deckId: deckId);
          return _fadeSlidePage(context, state, CardEditorPage(args: args));
        },
      ),
      GoRoute(
        path: '/decks/:deckId/cards/import',
        pageBuilder: (context, state) => _fadeSlidePage(
          context,
          state,
          CardImportPage(deckId: state.pathParameters['deckId']!),
        ),
      ),
      GoRoute(
        path: '/start',
        pageBuilder: (context, state) {
          final query = state.uri.queryParameters;
          return _fadeSlidePage(
            context,
            state,
            StartFlowPage(
              initialMode: query['mode'] == 'new' ? 'new' : 'due',
              initialDeckId: query['deck_id'],
            ),
          );
        },
      ),
      GoRoute(
        path: '/review',
        pageBuilder: (context, state) =>
            _fadeSlidePage(context, state, const ReviewPage()),
      ),
      GoRoute(
        path: '/stats',
        pageBuilder: (context, state) =>
            _fadeSlidePage(context, state, const StatsPage()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) =>
            _fadeSlidePage(context, state, const SettingsPage()),
      ),
      GoRoute(
        path: '/settings/logs',
        pageBuilder: (context, state) =>
            _fadeSlidePage(context, state, const LogsPage()),
      ),
    ],
  );

  ref.onDispose(authRevision.dispose);
  ref.listen(authProvider, (prev, next) {
    if (!identical(prev, next)) authRevision.value++;
  });
  return router;
});

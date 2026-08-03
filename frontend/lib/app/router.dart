import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/pages/login_page.dart';
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

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final autoRefreshObserver = AutoRefreshNavigatorObserver(
    onDataRouteChanged: () async {
      if (!ref.read(authProvider).isAuthenticated) return;
      await ref.read(dataRefreshControllerProvider).refreshFromServer();
    },
  );

  return GoRouter(
    initialLocation: '/home',
    observers: [autoRefreshObserver],
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

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
});

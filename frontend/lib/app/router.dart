import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/pages/login_page.dart';
import '../auth/pages/register_page.dart';
import '../auth/providers/auth_provider.dart';
import '../card/pages/card_editor_page.dart';
import '../card/pages/card_import_page.dart';
import '../card/pages/card_list_page.dart';
import '../deck/pages/deck_list_page.dart';
import '../home/pages/home_page.dart';
import '../review/pages/review_page.dart';
import '../review/pages/start_flow_page.dart';
import '../settings/pages/settings_page.dart';
import '../stats/pages/stats_page.dart';

CustomTransitionPage<Object?> _fadeSlidePage(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<Object?>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
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

  return GoRouter(
    initialLocation: '/home',
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
            _fadeSlidePage(state, const LoginPage()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) =>
            _fadeSlidePage(state, const RegisterPage()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) =>
            _fadeSlidePage(state, const HomePage()),
      ),
      GoRoute(
        path: '/decks',
        pageBuilder: (context, state) =>
            _fadeSlidePage(state, const DeckListPage()),
      ),
      GoRoute(
        path: '/decks/:deckId/cards',
        pageBuilder: (context, state) => _fadeSlidePage(
          state,
          CardListPage(deckId: state.pathParameters['deckId']!),
        ),
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
          return _fadeSlidePage(state, CardEditorPage(args: args));
        },
      ),
      GoRoute(
        path: '/decks/:deckId/cards/import',
        pageBuilder: (context, state) => _fadeSlidePage(
          state,
          CardImportPage(deckId: state.pathParameters['deckId']!),
        ),
      ),
      GoRoute(
        path: '/start',
        pageBuilder: (context, state) =>
            _fadeSlidePage(state, const StartFlowPage()),
      ),
      GoRoute(
        path: '/review',
        pageBuilder: (context, state) =>
            _fadeSlidePage(state, const ReviewPage()),
      ),
      GoRoute(
        path: '/stats',
        pageBuilder: (context, state) =>
            _fadeSlidePage(state, const StatsPage()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) =>
            _fadeSlidePage(state, const SettingsPage()),
      ),
    ],
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/pages/login_page.dart';
import '../auth/pages/register_page.dart';
import '../deck/pages/deck_list_page.dart';
import '../card/pages/card_list_page.dart';
import '../card/pages/card_edit_page.dart';
import '../review/pages/review_page.dart';
import '../stats/pages/stats_page.dart';
import '../stats/pages/deck_stats_page.dart';
import '../settings/pages/settings_page.dart';
import '../auth/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/decks',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/decks';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/decks',
        builder: (context, state) => const DeckListPage(),
      ),
      GoRoute(
        path: '/decks/:deckId/cards',
        builder: (context, state) => CardListPage(
          deckId: state.pathParameters['deckId']!,
        ),
      ),
      GoRoute(
        path: '/decks/:deckId/cards/create',
        builder: (context, state) => CardEditPage(
          deckId: state.pathParameters['deckId']!,
        ),
      ),
      GoRoute(
        path: '/decks/:deckId/cards/:cardId/edit',
        builder: (context, state) => CardEditPage(
          deckId: state.pathParameters['deckId']!,
          cardId: state.pathParameters['cardId'],
        ),
      ),
      GoRoute(
        path: '/review',
        builder: (context, state) => const ReviewPage(),
      ),
      GoRoute(
        path: '/review/due',
        builder: (context, state) => const ReviewPage(filter: 'due'),
      ),
      GoRoute(
        path: '/review/new',
        builder: (context, state) => const ReviewPage(filter: 'new'),
      ),
      GoRoute(
        path: '/decks/:deckId/stats',
        builder: (context, state) => DeckStatsPage(
          deckId: state.pathParameters['deckId']!,
        ),
      ),
      GoRoute(
        path: '/stats',
        builder: (context, state) => const StatsPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});
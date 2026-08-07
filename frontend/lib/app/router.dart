import 'dart:async';

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
    transitionDuration: reducedDuration(context, KarisMotion.page),
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

/// Tab 页使用无转场页面：四个 Tab 由 IndexedStack 保活，
/// 切换时零重建、零转场动画，避免桌面端整页重建导致的卡顿。
Page<Object?> _tabPage(GoRouterState state, Widget child) {
  return NoTransitionPage<Object?>(key: state.pageKey, child: child);
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
      // 主壳：四个 Tab 用 StatefulShellRoute.indexedStack 保活，
      // 切换只改可见 index，页面 State 全部保留，不再销毁重建。
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) =>
                    _tabPage(state, const HomePage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/decks',
                pageBuilder: (context, state) =>
                    _tabPage(state, const DeckListPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats',
                pageBuilder: (context, state) =>
                    _tabPage(state, const StatsPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) =>
                    _tabPage(state, const SettingsPage()),
              ),
            ],
          ),
        ],
      ),
      // 全屏子页面：在 shell 之上 push，保留返回路径与转场。
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

/// 主壳：渲染 IndexedStack 并在 Tab 切换时做一次静默同步，保证数据新鲜。
///
/// 切换 Tab 不再触发页面重建与转场动画；同步频率由 SyncService 的
/// 冷却与 in-flight 单飞兜底，不会产生重复请求。
class _MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const _MainShell({required this.navigationShell});

  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<_MainShell> {
  int _lastIndex = 0;

  @override
  void initState() {
    super.initState();
    _lastIndex = widget.navigationShell.currentIndex;
  }

  @override
  void didUpdateWidget(_MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final index = widget.navigationShell.currentIndex;
    if (index != _lastIndex) {
      _lastIndex = index;
      // 静默同步：数据变化会递增 dataVersion，各页 Provider 自行重算；
      // 失败静默保留旧数据，由下拉刷新兜底。
      unawaited(ref.read(dataRefreshControllerProvider).refreshFromServer());
    }
  }

  @override
  Widget build(BuildContext context) => widget.navigationShell;
}

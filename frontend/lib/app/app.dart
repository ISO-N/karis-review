import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show FlutterQuillLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../shared/providers/data_refresh_provider.dart';
import '../shared/widgets/karis_scroll_behavior.dart';
import '../shared/widgets/paper_texture.dart';
import 'router.dart';
import 'theme.dart';

class KarisReviewApp extends ConsumerStatefulWidget {
  const KarisReviewApp({super.key});

  @override
  ConsumerState<KarisReviewApp> createState() => _KarisReviewAppState();
}

class _KarisReviewAppState extends ConsumerState<KarisReviewApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(_refreshAfterResume());
  }

  Future<void> _refreshAfterResume() async {
    final controller = ref.read(dataRefreshControllerProvider);
    await controller.refreshFromServer();
    await controller.armDailyRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Karis Review',
      theme: appTheme,
      darkTheme: appDarkTheme,
      themeMode: ThemeMode.system,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness:
                isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarDividerColor: Colors.transparent,
          ),
          // 纸张纹理全局覆盖：RepaintBoundary 只光栅化一次，滚动/切页零成本；
          // 置于最上层，让纸面、卡片、导航都带同一层颗粒（alpha 极低）。
          child: Stack(
            children: [
              child ?? const SizedBox.shrink(),
              const Positioned.fill(child: PaperTexture()),
            ],
          ),
        );
      },
      scrollBehavior: const KarisScrollBehavior(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        ...FlutterQuillLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        KarisReviewLocalizations.delegate,
      ],
      supportedLocales: KarisReviewLocalizations.supportedLocales,
    );
  }
}

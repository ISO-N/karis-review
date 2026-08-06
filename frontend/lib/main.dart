import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 状态栏/导航栏样式由 app.dart 的 AnnotatedRegion 按主题亮度自动适配。
  runApp(const ProviderScope(child: KarisReviewApp()));
}

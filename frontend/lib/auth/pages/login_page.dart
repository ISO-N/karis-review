import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/widgets/app_semantics.dart';
import '../../shared/widgets/karis_glyph.dart';
import '../../shared/widgets/section_widgets.dart';
import '../providers/auth_provider.dart';

import '../../l10n/app_localizations.dart';
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      if (_emailController.text.trim().isEmpty ||
          !_emailController.text.contains('@')) {
        _emailFocus.requestFocus();
      } else {
        _passwordFocus.requestFocus();
      }
      return;
    }
    await ref
        .read(authProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    final l10n = KarisReviewLocalizations.of(context)!;
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 品牌签名：Karis 章 + 记忆刻度环，呼应下方"回到记忆刻度"。
                    const KarisGlyph(showRing: true),
                    const SizedBox(height: 24),
                    const Kicker('KARIS REVIEW'),
                    const SizedBox(height: 8),
                    KarisHeading(
                      child: Text('回到记忆刻度', style: karisDisplay(fontSize: 32)),
                    ),
                    const SizedBox(height: 10),
                    Text(
          l10n.authLoginSubtitle,
                      style: TextStyle(color: colors.stone, fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: '邮箱',
                        prefixIcon: Icon(Icons.mail_outline, size: 18),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入邮箱';
                        }
                        if (!value.contains('@')) return '邮箱格式无效';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: '密码',
                        prefixIcon: const Icon(Icons.lock_outline, size: 18),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword ? '显示密码' : '隐藏密码',
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return '请输入密码';
                        return null;
                      },
                      onFieldSubmitted: (_) => _login(),
                    ),
                    if (authState.error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        authState.error!,
                        style: TextStyle(
                          color: colors.cinnabar,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: authState.isLoading ? null : _login,
                      child: authState.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.surface,
                              ),
                            )
                          : const Text('登录'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('没有账号？立即注册'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/forgot-password'),
                      child: Text(
                        '忘记密码？',
                        style: TextStyle(
                          color: colors.stone,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

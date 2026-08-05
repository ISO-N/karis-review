import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/widgets/app_semantics.dart';
import '../../shared/widgets/section_widgets.dart';
import '../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  KarisReviewLocalizations get l10n => KarisReviewLocalizations.of(context)!;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _codeFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _codeSent = false;
  int _codeCountdown = 0;
  Timer? _codeTimer;

  @override
  void dispose() {
    _codeTimer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _codeFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _emailFocus.requestFocus();
      return;
    }
    await ref.read(authProvider.notifier).sendResetCode(email);
    if (!mounted) return;
    final state = ref.read(authProvider);
    if (state.error == null) {
      setState(() {
        _codeSent = true;
        _codeCountdown = 60;
      });
      _codeTimer?.cancel();
      _codeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _codeCountdown--;
          if (_codeCountdown <= 0) timer.cancel();
        });
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('验证码已发送，请查收邮件')));
    }
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).resetPassword(
          _emailController.text.trim(),
          _codeController.text.trim(),
          _passwordController.text,
        );
    if (!mounted) return;
    final state = ref.read(authProvider);
    if (state.error == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('密码已重置，请用新密码登录')));
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    const Kicker('KARIS REVIEW'),
                    const SizedBox(height: 8),
                    KarisHeading(
                      child: Text('找回密码', style: karisDisplay(fontSize: 32)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.authForgotPasswordSubtitle,
                      style: const TextStyle(
                        color: KarisColors.stone,
                        fontSize: 14,
                      ),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _codeController,
                            focusNode: _codeFocus,
                            keyboardType: TextInputType.number,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            decoration: const InputDecoration(
                              labelText: '验证码',
                              prefixIcon: Icon(
                                Icons.verified_outlined,
                                size: 18,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().length < 6) {
                                return '请输入验证码';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 10),
                        SizedBox(
                          height: 56,
                          child: OutlinedButton(
                            onPressed:
                                _codeCountdown > 0 || authState.isLoading
                                ? null
                                : _sendCode,
                            child: Text(
                              _codeCountdown > 0
                                  ? '${_codeCountdown}s'
                                  : _codeSent
                                  ? '重新发送'
                                  : '获取验证码',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: '新密码',
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
                        if (value.length < 6) return '密码至少 6 位';
                        return null;
                      },
                    ),
                    if (authState.error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        authState.error!,
                        style: const TextStyle(
                          color: KarisColors.cinnabar,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: authState.isLoading ? null : _reset,
                      child: authState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: KarisColors.surface,
                              ),
                            )
                          : const Text('重置密码'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('返回登录'),
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

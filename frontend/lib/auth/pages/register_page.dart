import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/widgets/app_feedback.dart';
import '../../shared/widgets/app_semantics.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/section_widgets.dart';
import '../models/auth_config.dart';
import '../providers/auth_provider.dart';

import '../../l10n/app_localizations.dart';
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  KarisReviewLocalizations get l10n => KarisReviewLocalizations.of(context)!;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _inviteController = TextEditingController();
  final _codeController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final _inviteFocus = FocusNode();
  final _codeFocus = FocusNode();
  bool _obscurePassword = true;
  int _codeCountdown = 0;
  Timer? _codeTimer;

  @override
  void dispose() {
    _codeTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _inviteController.dispose();
    _codeController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _inviteFocus.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _sendCode(AuthConfig config) async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _emailFocus.requestFocus();
      return;
    }
    if (config.inviteCodeRequired && _inviteController.text.trim().isEmpty) {
      _inviteFocus.requestFocus();
      return;
    }
    await ref.read(authProvider.notifier).sendRegisterCode(email);
    if (!mounted) return;
    final state = ref.read(authProvider);
    if (state.error == null) {
      setState(() => _codeCountdown = 60);
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
      showKarisFeedback(
        context,
        tone: KarisFeedbackTone.success,
        title: '验证码已发送，请查收邮件',
      );
    }
  }

  Future<void> _register(AuthConfig config) async {
    if (!_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      if (email.isEmpty || !email.contains('@')) {
        _emailFocus.requestFocus();
      } else if (_passwordController.text.isEmpty ||
          _passwordController.text.length < 6) {
        _passwordFocus.requestFocus();
      } else if (config.inviteCodeRequired &&
          _inviteController.text.trim().isEmpty) {
        _inviteFocus.requestFocus();
      } else if (_codeController.text.trim().length < 6) {
        _codeFocus.requestFocus();
      } else {
        _confirmFocus.requestFocus();
      }
      return;
    }
    await ref.read(authProvider.notifier).register(
          _emailController.text.trim(),
          _passwordController.text,
          inviteCode: config.inviteCodeRequired
              ? _inviteController.text.trim()
              : null,
          verificationCode: _codeController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final authConfig = ref.watch(authConfigProvider);

    return Scaffold(
      body: SafeArea(
        child: authConfig.when(
          loading: () => const LoadingWidget(),
          error: (_, _) => AppErrorWidget(
            message: '无法获取注册配置',
            onRetry: () => ref.invalidate(authConfigProvider),
          ),
          data: (config) => _buildForm(authState, config),
        ),
      ),
    );
  }

  Widget _buildForm(AuthState authState, AuthConfig config) {
    final colors = context.karisColors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 54,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.ink,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'K',
                    style: TextStyle(
                      color: colors.surface,
                      fontFamily: KarisTheme.displayFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 24),
                const Kicker('KARIS REVIEW'),
                SizedBox(height: 8),
                KarisHeading(
                  child: Text('创建账号', style: karisDisplay(fontSize: 32)),
                ),
                SizedBox(height: 10),
                Text(
          l10n.authRegisterSubtitle,
                  style: TextStyle(color: colors.stone, fontSize: 14),
                ),
                SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.newUsername],
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
                SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  obscureText: _obscurePassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.newPassword],
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
                    if (value.length < 6) return '密码至少 6 位';
                    return null;
                  },
                ),
                SizedBox(height: 14),
                TextFormField(
                  controller: _confirmController,
                  focusNode: _confirmFocus,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: const InputDecoration(
                    labelText: '确认密码',
                    prefixIcon: Icon(Icons.lock_outline, size: 18),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) return '两次密码不一致';
                    return null;
                  },
                ),
                if (config.inviteCodeRequired) ...[
                  SizedBox(height: 14),
                  TextFormField(
                    controller: _inviteController,
                    focusNode: _inviteFocus,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: '邀请码',
                      prefixIcon: Icon(Icons.vpn_key_outlined, size: 18),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入邀请码';
                      }
                      return null;
                    },
                  ),
                ],
                SizedBox(height: 14),
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
                          labelText: '邮箱验证码',
                          prefixIcon: Icon(Icons.verified_outlined, size: 18),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 6) {
                            return '请输入邮箱验证码';
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
                            : () => _sendCode(config),
                        child: Text(
                          _codeCountdown > 0 ? '${_codeCountdown}s' : '获取验证码',
                        ),
                      ),
                    ),
                  ],
                ),
                if (authState.error != null) ...[
                  SizedBox(height: 14),
                  Text(
                    authState.error!,
                    style: TextStyle(
                      color: colors.cinnabar,
                      fontSize: 13,
                    ),
                  ),
                ],
                SizedBox(height: 24),
                FilledButton(
                  onPressed: authState.isLoading ? null : () => _register(config),
                  child: authState.isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.surface,
                          ),
                        )
                      : const Text('注册'),
                ),
                SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('已有账号？立即登录'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

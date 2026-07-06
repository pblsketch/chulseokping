import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../core/result/result.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum _ResetStep { email, reset }

/// M5: 교사 비밀번호 재설정 — 메일 OTP 검증 후 새 비밀번호 적용.
/// (학생은 이메일이 없다 — 담임의 연결 코드 재발급이 학생용 재설정이다.)
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();

  _ResetStep _step = _ResetStep.email;
  String? _errorMessage;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    final result = await ref
        .read(requestPasswordResetProvider)
        .call(_emailController.text);
    if (!mounted) return;
    switch (result) {
      case Ok():
        setState(() => _step = _ResetStep.reset);
      case Err(:final failure):
        setState(() => _errorMessage = failure.message);
    }
    if (mounted) setState(() => _submitting = false);
  }

  Future<void> _confirmReset() async {
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    final result = await ref
        .read(confirmPasswordResetProvider)
        .call(
          email: _emailController.text,
          token: _otpController.text,
          newPassword: _passwordController.text,
        );
    if (!mounted) return;
    switch (result) {
      case Ok():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('비밀번호가 변경됐어요 — 다시 로그인해 주세요')),
        );
        context.go('/login');
      case Err(:final failure):
        setState(() {
          _submitting = false;
          _errorMessage = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 재설정')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_step == _ResetStep.email) ...[
                  const Text(
                    '가입한 이메일로 6자리 코드를 보내드려요.',
                    style: AppTypography.body,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: '이메일'),
                    onSubmitted: (_) => _requestReset(),
                  ),
                ] else ...[
                  Text(
                    '${_emailController.text.trim()} 주소로 보낸\n6자리 코드를 입력해 주세요.',
                    style: AppTypography.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: AppTypography.mono.copyWith(fontSize: 24),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: '인증 코드',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '새 비밀번호 (8자 이상)',
                    ),
                    onSubmitted: (_) => _confirmReset(),
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _errorMessage!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: _submitting
                      ? null
                      : (_step == _ResetStep.email
                            ? _requestReset
                            : _confirmReset),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_step == _ResetStep.email ? '코드 보내기' : '비밀번호 변경'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

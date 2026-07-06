import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../core/result/result.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/value_objects/sign_up_outcome.dart';
import 'auth_controller.dart';

enum _SignUpStep { form, verify }

/// M5: 교사 회원가입 — 이메일+비밀번호 → (인증 활성 시) 메일 OTP → 프로필 생성.
class TeacherSignUpPage extends ConsumerStatefulWidget {
  const TeacherSignUpPage({super.key});

  @override
  ConsumerState<TeacherSignUpPage> createState() => _TeacherSignUpPageState();
}

class _TeacherSignUpPageState extends ConsumerState<TeacherSignUpPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _otpController = TextEditingController();

  _SignUpStep _step = _SignUpStep.form;
  String? _errorMessage;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _finishWithProfile() async {
    final result = await ref
        .read(completeTeacherProfileProvider)
        .call(name: _nameController.text);
    if (!mounted) return;
    switch (result) {
      case Ok(:final UserProfile value):
        // 라우터 redirect가 교사 홈으로 보낸다
        ref.read(authControllerProvider.notifier).setProfile(value);
      case Err(:final failure):
        setState(() => _errorMessage = failure.message);
    }
  }

  Future<void> _submitForm() async {
    if (_passwordController.text != _passwordConfirmController.text) {
      setState(() => _errorMessage = '비밀번호가 서로 달라요');
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = '이름을 입력해 주세요');
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    final result = await ref
        .read(signUpTeacherProvider)
        .call(email: _emailController.text, password: _passwordController.text);
    if (!mounted) return;
    switch (result) {
      case Ok(:final SignUpOutcome value):
        if (value == SignUpOutcome.sessionReady) {
          await _finishWithProfile();
        } else {
          setState(() => _step = _SignUpStep.verify);
        }
      case Err(:final failure):
        setState(() => _errorMessage = failure.message);
    }
    if (mounted) setState(() => _submitting = false);
  }

  Future<void> _submitOtp() async {
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    final result = await ref
        .read(verifyTeacherEmailProvider)
        .call(email: _emailController.text, token: _otpController.text);
    if (!mounted) return;
    switch (result) {
      case Ok():
        await _finishWithProfile();
      case Err(:final failure):
        setState(() => _errorMessage = failure.message);
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('교사 회원가입')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _step == _SignUpStep.form
                  ? _buildForm()
                  : _buildVerify(),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildForm() {
    return [
      TextField(
        controller: _nameController,
        decoration: const InputDecoration(labelText: '이름'),
      ),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        decoration: const InputDecoration(labelText: '이메일'),
      ),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _passwordController,
        obscureText: true,
        decoration: const InputDecoration(labelText: '비밀번호 (8자 이상)'),
      ),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _passwordConfirmController,
        obscureText: true,
        decoration: const InputDecoration(labelText: '비밀번호 확인'),
        onSubmitted: (_) => _submitForm(),
      ),
      ..._errorAndButton(onPressed: _submitForm, label: '가입하기'),
      const SizedBox(height: AppSpacing.md),
      TextButton(
        onPressed: () => context.go('/login'),
        child: const Text('이미 계정이 있어요 — 로그인'),
      ),
    ];
  }

  List<Widget> _buildVerify() {
    return [
      Text(
        '${_emailController.text.trim()} 주소로\n6자리 인증 코드를 보냈어요.',
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
        decoration: const InputDecoration(labelText: '인증 코드', counterText: ''),
        onSubmitted: (_) => _submitOtp(),
      ),
      ..._errorAndButton(onPressed: _submitOtp, label: '인증하고 시작하기'),
    ];
  }

  List<Widget> _errorAndButton({
    required VoidCallback onPressed,
    required String label,
  }) {
    return [
      if (_errorMessage != null) ...[
        const SizedBox(height: AppSpacing.md),
        Text(
          _errorMessage!,
          style: AppTypography.caption.copyWith(color: AppColors.danger),
        ),
      ],
      const SizedBox(height: AppSpacing.xl),
      ElevatedButton(
        onPressed: _submitting ? null : onPressed,
        child: _submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    ];
  }
}

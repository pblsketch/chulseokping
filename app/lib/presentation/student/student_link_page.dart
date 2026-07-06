import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../shared/auth_controller.dart';

/// M5: 학생 기기 연결 — 선생님께 받은 연결 코드 1회 입력으로 로그인.
/// 계정 자체는 교사가 만들었다(하이브리드 모델) — 학생은 이메일·비밀번호를 모른다.
class StudentLinkPage extends ConsumerStatefulWidget {
  const StudentLinkPage({super.key});

  @override
  ConsumerState<StudentLinkPage> createState() => _StudentLinkPageState();
}

class _StudentLinkPageState extends ConsumerState<StudentLinkPage> {
  final _codeController = TextEditingController();
  String? _errorMessage;
  bool _submitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    final failure = await ref
        .read(authControllerProvider.notifier)
        .signInWithLinkCode(_codeController.text);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _errorMessage = failure?.message;
    });
    // 성공 시 라우터 redirect가 학생 홈으로 보낸다.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('학생 연결')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '선생님께 받은 연결 코드를 입력하면\n이 폰으로 출석할 수 있어요.',
                  style: AppTypography.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  style: AppTypography.mono.copyWith(fontSize: 20),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: '연결 코드',
                    hintText: 'ABCD-EFGH-JKLM',
                  ),
                  onSubmitted: (_) => _submit(),
                ),
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
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('연결하기'),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  '코드가 없거나 만료됐다면 선생님께 재발급을 요청하세요.',
                  style: AppTypography.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

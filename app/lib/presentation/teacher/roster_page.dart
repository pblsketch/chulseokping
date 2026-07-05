import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/result/result.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/secure_random.dart';
import '../../domain/entities/student.dart';
import 'session_page.dart' show sessionStudentsProvider;

/// TE-6: 명단 관리 — 동의 확인(PI-2) + 키오스크 PIN 발급.
/// ⚠ 동의 미확인 학생은 서버가 모든 출결 수집을 거부한다 — UI는 상태 표시와 확인 액션만.
class RosterPage extends ConsumerWidget {
  const RosterPage({super.key, required this.classId, required this.className});

  final String classId;
  final String className;

  Future<void> _confirmConsent(
    BuildContext context,
    WidgetRef ref,
    Student student,
  ) async {
    final agreed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('보호자 동의 확인'),
        content: Text(
          '${student.name} 학생의 보호자에게 개인정보 처리방침 동의를 받으셨나요?\n\n'
          '수집 항목: 이름·학번·출결 상태·시각·방식 (위치 좌표는 수집하지 않음)\n'
          '동의 전에는 어떤 방식으로도 출결이 기록되지 않아요.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('아직'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('동의 받음'),
          ),
        ],
      ),
    );
    if (agreed != true || !context.mounted) return;

    final result = await ref
        .read(confirmGuardianConsentProvider)
        .call(student.id);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        ref.invalidate(sessionStudentsProvider(classId));
      case Err(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _issuePin(
    BuildContext context,
    WidgetRef ref,
    Student student,
  ) async {
    final pin = SecureRandom.studentPin();
    final result = await ref
        .read(setStudentPinProvider)
        .call(studentId: student.id, pin: pin);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('${student.name} PIN 발급'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '학생에게 이 PIN을 전달하세요. 지금만 표시돼요.',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(pin, style: AppTypography.mono.copyWith(fontSize: 40)),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      case Err(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(sessionStudentsProvider(classId));
    return Scaffold(
      appBar: AppBar(title: Text('$className · 명단 관리')),
      body: students.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (list) => list.isEmpty
            ? const Center(
                child: Text('학생이 아직 없어요', style: AppTypography.title),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: list.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final student = list[index];
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      side: const BorderSide(color: AppColors.borderDefault),
                    ),
                    title: Text(student.name, style: AppTypography.bodyStrong),
                    subtitle: Text(
                      student.studentNumber,
                      style: AppTypography.mono.copyWith(fontSize: 13),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (student.consentConfirmed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusPill,
                              ),
                            ),
                            child: Text(
                              '동의 확인됨',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                          )
                        else
                          OutlinedButton(
                            onPressed: () =>
                                _confirmConsent(context, ref, student),
                            child: const Text('동의 확인'),
                          ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton(
                          tooltip: 'PIN 발급',
                          onPressed: student.consentConfirmed
                              ? () => _issuePin(context, ref, student)
                              : null, // 동의 전에는 PIN도 발급하지 않음
                          icon: const Icon(Icons.pin_outlined),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

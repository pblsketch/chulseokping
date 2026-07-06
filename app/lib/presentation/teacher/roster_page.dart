import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/result/result.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/secure_random.dart';
import '../../domain/entities/created_student.dart';
import '../../domain/entities/new_student_entry.dart';
import '../../domain/entities/student.dart';
import 'session_page.dart' show sessionStudentsProvider;

/// TE-6: 명단 관리 — 동의 확인(PI-2) + 키오스크 PIN 발급.
/// M5: 학생 계정 일괄 생성 + 연결 코드 발급(하이브리드 모델).
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

  Future<void> _addStudents(BuildContext context, WidgetRef ref) async {
    final entries = await showDialog<List<NewStudentEntry>>(
      context: context,
      builder: (context) => const _AddStudentsDialog(),
    );
    if (entries == null || entries.isEmpty || !context.mounted) return;

    final result = await ref
        .read(createStudentsProvider)
        .call(classId: classId, entries: entries);
    if (!context.mounted) return;
    switch (result) {
      case Ok(:final List<CreatedStudent> value):
        ref.invalidate(sessionStudentsProvider(classId));
        await showDialog<void>(
          context: context,
          builder: (context) => _CreatedStudentsDialog(results: value),
        );
      case Err(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _issueLinkCode(
    BuildContext context,
    WidgetRef ref,
    Student student,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('연결 코드 재발급'),
        content: Text(
          '${student.name} 학생의 새 연결 코드를 발급할까요?\n'
          '기존 코드는 즉시 무효화돼요. (연결된 폰의 로그인은 유지)',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('재발급'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref.read(issueLinkCodeProvider).call(student.id);
    if (!context.mounted) return;
    switch (result) {
      case Ok(:final value):
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('${student.name} 연결 코드'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '학생이 자기 폰의 "연결 코드로 시작"에 입력하면 돼요.\n48시간 동안 1회만 쓸 수 있어요.',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: AppSpacing.lg),
                SelectableText(
                  value.code,
                  style: AppTypography.mono.copyWith(fontSize: 26),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Clipboard.setData(ClipboardData(text: value.code)),
                child: const Text('복사'),
              ),
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
      appBar: AppBar(
        title: Text('$className · 명단 관리'),
        actions: [
          IconButton(
            tooltip: '학생 추가',
            onPressed: () => _addStudents(context, ref),
            icon: const Icon(Icons.person_add_alt),
          ),
        ],
      ),
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
                        IconButton(
                          tooltip: '연결 코드 재발급',
                          onPressed: () =>
                              _issueLinkCode(context, ref, student),
                          icon: const Icon(Icons.phonelink_ring_outlined),
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

/// 학생 일괄 추가 입력 — "학번 이름" 줄 단위 붙여넣기 + 보호자 동의 일괄 확인.
class _AddStudentsDialog extends ConsumerStatefulWidget {
  const _AddStudentsDialog();

  @override
  ConsumerState<_AddStudentsDialog> createState() => _AddStudentsDialogState();
}

class _AddStudentsDialogState extends ConsumerState<_AddStudentsDialog> {
  final _textController = TextEditingController();
  bool _guardianConsented = false;
  List<String> _errors = const [];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = ref
        .read(parseStudentRosterInputProvider)
        .call(_textController.text, guardianConsented: _guardianConsented);
    if (parsed.hasErrors) {
      setState(() => _errors = parsed.errors);
      return;
    }
    if (parsed.entries.isEmpty) {
      setState(() => _errors = const ['추가할 학생을 입력해 주세요']);
      return;
    }
    Navigator.pop(context, parsed.entries);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('학생 추가'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '한 줄에 한 명씩 "학번 이름" 형식으로 입력하세요.\n'
              '(엑셀 명렬표에서 붙여넣기 가능)',
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _textController,
              maxLines: 8,
              style: AppTypography.mono.copyWith(fontSize: 14),
              decoration: const InputDecoration(
                hintText: '10101 김철수\n10102 이영희',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            CheckboxListTile(
              value: _guardianConsented,
              onChanged: (v) => setState(() => _guardianConsented = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                '위 학생 전원의 보호자 동의를 받았어요 (서면 등)',
                style: AppTypography.caption,
              ),
            ),
            if (_errors.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              ..._errors
                  .take(5)
                  .map(
                    (e) => Text(
                      e,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _submit, child: const Text('계정 만들기')),
      ],
    );
  }
}

/// 일괄 생성 결과 — 연결 코드는 이 화면에서만 평문으로 보인다(서버는 해시만 보관).
class _CreatedStudentsDialog extends StatelessWidget {
  const _CreatedStudentsDialog({required this.results});

  final List<CreatedStudent> results;

  static String _rowError(String? error) => switch (error) {
    'invalid_name' => '이름이 올바르지 않아요',
    'invalid_student_number' => '학번이 올바르지 않아요',
    'duplicate_student_number' => '이미 있는 학번이에요',
    _ => '생성 실패 ($error)',
  };

  @override
  Widget build(BuildContext context) {
    final okRows = results.where((r) => r.ok).toList();
    final failRows = results.where((r) => !r.ok).toList();
    final copyText = okRows
        .map((r) => '${r.studentNumber}\t${r.name}\t${r.linkCode}')
        .join('\n');

    return AlertDialog(
      title: Text('학생 ${okRows.length}명 추가됨'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '연결 코드는 지금만 표시돼요 — 학생에게 전달하세요.\n'
              '잃어버리면 명단에서 재발급하면 돼요.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final row in okRows)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${row.name} (${row.studentNumber})',
                                style: AppTypography.body,
                              ),
                            ),
                            SelectableText(
                              row.linkCode ?? '',
                              style: AppTypography.mono.copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    for (final row in failRows)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: Text(
                          '${row.name.isEmpty ? row.studentNumber : row.name}'
                          ' — ${_rowError(row.error)}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (okRows.isNotEmpty)
          TextButton(
            onPressed: () => Clipboard.setData(ClipboardData(text: copyText)),
            child: const Text('전체 복사'),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}

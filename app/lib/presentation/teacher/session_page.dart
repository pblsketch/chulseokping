import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/di/providers.dart';
import '../../core/result/result.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/rotating_code.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/student.dart';
import '../../domain/value_objects/absence_reason.dart';
import '../../domain/value_objects/attendance_status.dart';
import '../shared/status_chip.dart';
import 'session_roster.dart';
import 'teacher_beacon_controller.dart';

final sessionStudentsProvider = FutureProvider.family<List<Student>, String>((
  ref,
  classId,
) async {
  final result = await ref.watch(rosterRepositoryProvider).studentsOf(classId);
  return result.fold(
    (students) => students,
    (failure) => throw failure.message,
  );
});

final liveRecordsProvider =
    StreamProvider.family<List<AttendanceRecord>, String>(
      (ref, sessionId) =>
          ref.watch(watchLiveAttendanceProvider).call(sessionId),
    );

final classSecretProvider = FutureProvider.family<String, String>((
  ref,
  classId,
) async {
  final result = await ref
      .watch(sessionRepositoryProvider)
      .classSecret(classId);
  return result.fold((secret) => secret, (failure) => throw failure.message);
});

/// 세션 대시보드 (TE-2 실시간 / TE-3 수동 수정 / KO-2 회전 QR).
class SessionPage extends ConsumerWidget {
  const SessionPage({
    super.key,
    required this.sessionId,
    required this.classId,
  });

  final String sessionId;
  final String classId;

  Future<void> _endSession(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(endSessionProvider).call(sessionId);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        context.go('/teacher');
      case Err(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(sessionStudentsProvider(classId));
    final records = ref.watch(liveRecordsProvider(sessionId));

    final presentCount =
        records.value
            ?.where((r) => r.status == AttendanceStatus.present)
            .length ??
        0;
    final total = students.value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('출석 $presentCount / $total', style: AppTypography.h2),
        actions: [
          TextButton.icon(
            onPressed: () => _endSession(context, ref),
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('세션 종료'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                RotatingQrCard(sessionId: sessionId, classId: classId),
                const SizedBox(height: AppSpacing.sm),
                TeacherBeaconBadge(classId: classId),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: switch ((students, records)) {
              (AsyncData(value: final list), _) => _RosterList(
                rows: mergeRoster(list, records.value ?? []),
                sessionId: sessionId,
              ),
              (AsyncError(:final error), _) => Center(child: Text('$error')),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class _RosterList extends ConsumerWidget {
  const _RosterList({required this.rows, required this.sessionId});

  final List<SessionRosterRow> rows;
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final row = rows[index];
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: const BorderSide(color: AppColors.borderDefault),
          ),
          leading: CircleAvatar(
            backgroundColor: AppColors.bgSubtle,
            child: Text(
              row.student.name.characters.first,
              style: AppTypography.bodyStrong,
            ),
          ),
          title: Text(row.student.name, style: AppTypography.bodyStrong),
          subtitle: Text(
            row.student.studentNumber,
            style: AppTypography.mono.copyWith(fontSize: 13),
          ),
          trailing: StatusChip(status: row.record?.status),
          onTap: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (context) =>
                ManualEditSheet(row: row, sessionId: sessionId),
          ),
        );
      },
    );
  }
}

/// KO-2: 회전 QR — 5초 TOTP + 잔여 링. 검증은 서버가 한다.
class RotatingQrCard extends ConsumerStatefulWidget {
  const RotatingQrCard({
    super.key,
    required this.sessionId,
    required this.classId,
  });

  final String sessionId;
  final String classId;

  @override
  ConsumerState<RotatingQrCard> createState() => _RotatingQrCardState();
}

class _RotatingQrCardState extends ConsumerState<RotatingQrCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final secret = ref.watch(classSecretProvider(widget.classId));
    return secret.when(
      loading: () => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Text('$error', style: AppTypography.caption),
      data: (secretHex) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final code = RotatingCode.totpCode(secretHex, timestampMs: now);
        final remaining = RotatingCode.remainingMs(now);
        final fraction = remaining / (RotatingCode.periodSeconds * 1000);
        final payload = jsonEncode({
          'v': 1,
          'sid': widget.sessionId,
          'c': code,
        });
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                QrImageView(data: payload, size: 148),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '학생이 이 QR을 스캔하면 출석돼요',
                        style: AppTypography.bodyStrong,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              value: fraction,
                              strokeWidth: 3,
                              color: fraction < 0.25
                                  ? AppColors.warning
                                  : AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text('5초마다 갱신', style: AppTypography.caption),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// BYOD 비컨 송신 상태 — 세션 화면에 머무는 동안 이 기기가 비컨 역할을 한다.
/// 색만으로 전달하지 않고 항상 텍스트 병기 (design.md).
class TeacherBeaconBadge extends ConsumerStatefulWidget {
  const TeacherBeaconBadge({super.key, required this.classId});

  final String classId;

  @override
  ConsumerState<TeacherBeaconBadge> createState() => _TeacherBeaconBadgeState();
}

class _TeacherBeaconBadgeState extends ConsumerState<TeacherBeaconBadge> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(teacherBeaconControllerProvider(widget.classId).notifier)
          .start(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherBeaconControllerProvider(widget.classId));
    final (icon, color, text) = switch (state) {
      TeacherBeaconIdle() => (
        Icons.wifi_tethering,
        AppColors.textDisabled,
        '비컨 준비 중...',
      ),
      TeacherBeaconOn() => (
        Icons.wifi_tethering,
        AppColors.success,
        '비컨 송신 중 — 근처 학생은 자동 출석돼요',
      ),
      TeacherBeaconOff(:final message) => (
        Icons.wifi_tethering_off,
        AppColors.warning,
        message,
      ),
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            text,
            style: AppTypography.caption.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// TE-3: 수동 수정 시트 — 상태 5종 × 사유 4종 (2축).
class ManualEditSheet extends ConsumerStatefulWidget {
  const ManualEditSheet({
    super.key,
    required this.row,
    required this.sessionId,
  });

  final SessionRosterRow row;
  final String sessionId;

  @override
  ConsumerState<ManualEditSheet> createState() => _ManualEditSheetState();
}

class _ManualEditSheetState extends ConsumerState<ManualEditSheet> {
  late AttendanceStatus _status =
      widget.row.record?.status ?? AttendanceStatus.absent;
  late AbsenceReason? _reason =
      widget.row.record?.reason ??
      (_status == AttendanceStatus.present ? null : AbsenceReason.unrecognized);
  RecognizedCode? _reasonCode;
  final _detailController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final record = widget.row.record;
    final usecase = ref.read(updateAttendanceStatusProvider);
    final result = await usecase(
      recordId: record?.id,
      sessionId: record == null ? widget.sessionId : null,
      studentId: record == null ? widget.row.student.id : null,
      status: _status,
      reason: _status == AttendanceStatus.present ? null : _reason,
      reasonCode: _reason == AbsenceReason.recognized ? _reasonCode : null,
      reasonDetail: _detailController.text.isEmpty
          ? null
          : _detailController.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok():
        Navigator.pop(context);
      case Err(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.row.student.name} · ${widget.row.student.studentNumber}',
              style: AppTypography.h2,
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final status in AttendanceStatus.values)
                  ChoiceChip(
                    label: Text(status.label),
                    selected: _status == status,
                    onSelected: (_) => setState(() {
                      _status = status;
                      if (status == AttendanceStatus.present) _reason = null;
                      _reason ??= AbsenceReason.unrecognized;
                    }),
                  ),
              ],
            ),
            if (_status != AttendanceStatus.present) ...[
              const SizedBox(height: AppSpacing.lg),
              const Text('사유', style: AppTypography.bodyStrong),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final reason in AbsenceReason.values)
                    ChoiceChip(
                      label: Text(reason.label),
                      selected: _reason == reason,
                      onSelected: (_) => setState(() => _reason = reason),
                    ),
                ],
              ),
              if (_reason == AbsenceReason.recognized) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final code in RecognizedCode.values)
                      ChoiceChip(
                        label: Text(code.label),
                        selected: _reasonCode == code,
                        onSelected: (_) => setState(() => _reasonCode = code),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _detailController,
                decoration: const InputDecoration(labelText: '세부 사유 (선택)'),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}

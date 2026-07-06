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
import '../../domain/entities/session.dart';
import '../../domain/entities/student.dart';
import '../../domain/entities/suspicious_flag.dart';
import '../../domain/usecases/confirm_headcount.dart';
import '../../domain/value_objects/absence_reason.dart';
import '../../domain/value_objects/attendance_status.dart';
import '../shared/roster_providers.dart';
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

/// P0-3: 세션 의심 신호 (미확인 우선) — 배지·목록용.
final sessionFlagsProvider = FutureProvider.autoDispose
    .family<List<SuspiciousFlag>, String>((ref, sessionId) async {
      final result = await ref.watch(getSessionFlagsProvider).call(sessionId);
      return result.fold((flags) => flags, (failure) => throw failure.message);
    });

/// 세션 대시보드 (TE-2 실시간 / TE-3 수동 수정 / KO-2 회전 QR / P0-3 헤드카운트).
class SessionPage extends ConsumerWidget {
  const SessionPage({
    super.key,
    required this.sessionId,
    required this.classId,
  });

  final String sessionId;
  final String classId;

  /// P0-3: 종료 전 헤드카운트 원탭 확인 — 대학 '불시 점검'의 UX 내재화.
  /// 불일치면 세션을 유지한 채 명렬표에서 정정하게 한다 (자동 결석 확정 없음).
  Future<void> _endSession(BuildContext context, WidgetRef ref) async {
    final records = ref.read(liveRecordsProvider(sessionId)).value ?? [];
    final autoCount = ConfirmHeadcount.autoCount(records);

    if (autoCount > 0) {
      final decision = await showDialog<({bool matches, int? observed})>(
        context: context,
        builder: (context) => _HeadcountDialog(autoCount: autoCount),
      );
      if (decision == null || !context.mounted) return; // 취소 — 세션 유지

      final confirm = await ref
          .read(confirmHeadcountProvider)
          .call(
            sessionId: sessionId,
            matches: decision.matches,
            observedCount: decision.observed,
          );
      if (!context.mounted) return;
      if (confirm case Err(:final failure)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
        return;
      }
      if (!decision.matches) {
        ref.invalidate(sessionFlagsProvider(sessionId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('의심 신호로 기록했어요 — 명단에서 정정한 뒤 다시 종료하세요')),
        );
        return; // 세션 유지 → 아래 명렬표에서 수동 정정
      }
    }

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
          _FlagsBadge(sessionId: sessionId),
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
                SessionWindowBar(sessionId: sessionId, classId: classId),
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

/// P0-3: 마감 헤드카운트 원탭 — "자동 출석 N명, 실제 인원과 맞나요?"
class _HeadcountDialog extends StatefulWidget {
  const _HeadcountDialog({required this.autoCount});

  final int autoCount;

  @override
  State<_HeadcountDialog> createState() => _HeadcountDialogState();
}

class _HeadcountDialogState extends State<_HeadcountDialog> {
  bool _askObserved = false;
  final _observedController = TextEditingController();

  @override
  void dispose() {
    _observedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('출석 인원 확인'),
      content: _askObserved
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '실제 교실 인원을 입력해 주세요 (선택).\n의심 신호로 기록되고, 출석은 명단에서 정정하면 돼요.',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _observedController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: '실제 인원 수'),
                ),
              ],
            )
          : Text(
              'QR·BLE 자동 출석이 ${widget.autoCount}명이에요.\n'
              '실제 교실 인원과 맞나요?\n\n'
              '(폰만 두 대 들고 온 대리출석은 이 확인으로만 잡을 수 있어요)',
              style: AppTypography.body,
            ),
      actions: _askObserved
          ? [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, (
                  matches: false,
                  observed: int.tryParse(_observedController.text.trim()),
                )),
                child: const Text('기록하고 명단 확인'),
              ),
            ]
          : [
              TextButton(
                onPressed: () => setState(() => _askObserved = true),
                child: const Text('아니요, 달라요'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(context, (matches: true, observed: null)),
                child: const Text('네, 맞아요 — 종료'),
              ),
            ],
    );
  }
}

/// P0-3: 의심 신호 배지 — 미확인 신호가 있을 때만 표시 (로그-온리, 판단은 교사).
class _FlagsBadge extends ConsumerWidget {
  const _FlagsBadge({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(sessionFlagsProvider(sessionId)).value ?? const [];
    final unreviewed = flags.where((f) => !f.reviewed).length;
    if (unreviewed == 0) return const SizedBox.shrink();

    return TextButton.icon(
      onPressed: () => showDialog<void>(
        context: context,
        builder: (context) => _FlagsDialog(sessionId: sessionId),
      ),
      icon: const Icon(Icons.warning_amber, color: AppColors.warning),
      label: Text(
        '의심 $unreviewed',
        style: AppTypography.bodyStrong.copyWith(color: AppColors.warning),
      ),
    );
  }
}

class _FlagsDialog extends ConsumerWidget {
  const _FlagsDialog({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(sessionFlagsProvider(sessionId));
    return AlertDialog(
      title: const Text('의심 신호'),
      content: SizedBox(
        width: 420,
        child: flags.when(
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text('$error', style: AppTypography.body),
          data: (list) => list.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text('의심 신호가 없어요', style: AppTypography.body),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Text(
                          '출석을 막지는 않아요 — 확인 후 필요하면 명단에서 정정하세요.',
                          style: AppTypography.caption,
                        ),
                      ),
                      for (final flag in list)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            flag.label,
                            style: AppTypography.bodyStrong,
                          ),
                          subtitle: Text(
                            '${flag.createdAt.toLocal()}'.substring(0, 16),
                            style: AppTypography.caption,
                          ),
                          trailing: flag.reviewed
                              ? Text('확인됨', style: AppTypography.caption)
                              : TextButton(
                                  onPressed: () async {
                                    final result = await ref
                                        .read(markFlagReviewedProvider)
                                        .call(flag.id);
                                    if (!context.mounted) return;
                                    switch (result) {
                                      case Ok():
                                        ref.invalidate(
                                          sessionFlagsProvider(sessionId),
                                        );
                                      case Err(:final failure):
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(failure.message),
                                          ),
                                        );
                                    }
                                  },
                                  child: const Text('확인'),
                                ),
                        ),
                    ],
                  ),
                ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}

/// P0-1: 수집 창 카운트다운 + 연장. 표시 전용 — 마감 판정 권위는 서버(now vs close_at).
/// 창 없는(수동 종료) 세션에서는 아무것도 그리지 않는다.
class SessionWindowBar extends ConsumerStatefulWidget {
  const SessionWindowBar({
    super.key,
    required this.sessionId,
    required this.classId,
  });

  final String sessionId;
  final String classId;

  @override
  ConsumerState<SessionWindowBar> createState() => _SessionWindowBarState();
}

class _SessionWindowBarState extends ConsumerState<SessionWindowBar> {
  Timer? _timer;
  bool _extending = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _extend() async {
    setState(() => _extending = true);
    final result = await ref.read(extendSessionProvider).call(widget.sessionId);
    if (!mounted) return;
    setState(() => _extending = false);
    if (result case Err(:final failure)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
    // 성공 시 sessions Realtime 스트림이 새 close_at을 밀어준다.
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeSessionProvider(widget.classId)).value;
    final Session? session = (active != null && active.id == widget.sessionId)
        ? active
        : null;
    final closeAt = session?.closeAt;
    if (closeAt == null) return const SizedBox.shrink();

    final remaining = closeAt.difference(DateTime.now());
    final expired = remaining.isNegative;
    final mm = remaining.inMinutes.toString().padLeft(2, '0');
    final ss = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    final color = expired
        ? AppColors.danger
        : (remaining.inMinutes < 2
              ? AppColors.warning
              : AppColors.textSecondary);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            expired ? '수집 시간이 끝났어요 — 곧 자동 종료돼요' : '수집 마감까지 $mm:$ss',
            style: AppTypography.caption.copyWith(color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: _extending ? null : _extend,
            child: const Text('+5분 연장'),
          ),
        ],
      ),
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

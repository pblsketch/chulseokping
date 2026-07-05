import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/di/providers.dart';
import '../../core/result/result.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/student.dart';
import '../../domain/value_objects/session_type.dart';
import '../shared/status_chip.dart';
import 'ledger_model.dart';
import 'session_page.dart' show sessionStudentsProvider;

/// 월별 데이터 묶음 — 기록·세션·학생을 한 번에 로드 (TE-4).
class MonthlyLedgerData {
  const MonthlyLedgerData({
    required this.records,
    required this.sessionsById,
    required this.studentsById,
  });

  final List<AttendanceRecord> records;
  final Map<String, Session> sessionsById;
  final Map<String, Student> studentsById;
}

typedef LedgerQuery = ({String classId, int year, int month});

final monthlyLedgerProvider =
    FutureProvider.family<MonthlyLedgerData, LedgerQuery>((ref, query) async {
      final recordsResult = await ref
          .watch(attendanceRepositoryProvider)
          .monthlyRecords(
            classId: query.classId,
            year: query.year,
            month: query.month,
          );
      final sessionsResult = await ref
          .watch(sessionRepositoryProvider)
          .monthlySessions(
            classId: query.classId,
            year: query.year,
            month: query.month,
          );
      final students = await ref.watch(
        sessionStudentsProvider(query.classId).future,
      );

      final records = recordsResult.fold(
        (value) => value,
        (failure) => throw failure.message,
      );
      final sessions = sessionsResult.fold(
        (value) => value,
        (failure) => throw failure.message,
      );
      return MonthlyLedgerData(
        records: records,
        sessionsById: {for (final s in sessions) s.id: s},
        studentsById: {for (final s in students) s.id: s},
      );
    });

/// TE-4 월별 일람표 + TE-5 나이스 예외 내보내기.
class LedgerPage extends ConsumerStatefulWidget {
  const LedgerPage({super.key, required this.classId, required this.className});

  final String classId;
  final String className;

  @override
  ConsumerState<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends ConsumerState<LedgerPage> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  SessionType? _typeFilter;

  LedgerQuery get _query =>
      (classId: widget.classId, year: _month.year, month: _month.month);

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  Future<void> _exportTsv(MonthlyLedgerData data) async {
    final rows = ref
        .read(buildNeisExceptionExportProvider)
        .call(
          records: data.records,
          sessionsById: data.sessionsById,
          studentsById: data.studentsById,
        );
    final result = await ref.read(exportRepositoryProvider).toTsv(rows);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        await Clipboard.setData(ClipboardData(text: value));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('예외 ${rows.length}건을 클립보드에 복사했어요 — 나이스에 붙여넣으세요'),
          ),
        );
      case Err(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _exportXlsx(MonthlyLedgerData data) async {
    final rows = ref
        .read(buildNeisExceptionExportProvider)
        .call(
          records: data.records,
          sessionsById: data.sessionsById,
          studentsById: data.studentsById,
        );
    final result = await ref.read(exportRepositoryProvider).toXlsx(rows);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(value)],
            subject:
                '출석핑 나이스 예외 ${_month.year}-${_month.month.toString().padLeft(2, '0')}',
          ),
        );
      case Err(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(monthlyLedgerProvider(_query));
    final monthLabel = '${_month.year}년 ${_month.month}월';

    return Scaffold(
      appBar: AppBar(title: Text('${widget.className} · 일람표')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _shiftMonth(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(monthLabel, style: AppTypography.h2),
                IconButton(
                  onPressed: () => _shiftMonth(1),
                  icon: const Icon(Icons.chevron_right),
                ),
                const Spacer(),
                SegmentedButton<SessionType?>(
                  segments: const [
                    ButtonSegment(value: null, label: Text('전체')),
                    ButtonSegment(
                      value: SessionType.homeroom,
                      label: Text('조회'),
                    ),
                    ButtonSegment(value: SessionType.period, label: Text('교시')),
                  ],
                  selected: {_typeFilter},
                  onSelectionChanged: (selection) =>
                      setState(() => _typeFilter = selection.first),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('$error')),
              data: (ledger) {
                final rows = buildLedgerRows(
                  records: ledger.records,
                  sessionsById: ledger.sessionsById,
                  studentsById: ledger.studentsById,
                  typeFilter: _typeFilter,
                );
                if (rows.isEmpty) {
                  return const Center(
                    child: Text('이 달 출결 기록이 없어요', style: AppTypography.title),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    return ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                        side: const BorderSide(color: AppColors.borderDefault),
                      ),
                      leading: Text(
                        '${row.session.date.month}/${row.session.date.day}',
                        style: AppTypography.mono.copyWith(fontSize: 13),
                      ),
                      title: Text(
                        '${row.student.name} · ${row.periodLabel}',
                        style: AppTypography.body,
                      ),
                      subtitle: row.record.reason == null
                          ? null
                          : Text(
                              '${row.record.reason!.label}'
                              '${row.record.reasonDetail == null ? '' : ' · ${row.record.reasonDetail}'}',
                              style: AppTypography.caption,
                            ),
                      trailing: StatusChip(status: row.record.status),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: data.maybeWhen(
                data: (ledger) => Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _exportTsv(ledger),
                        icon: const Icon(Icons.copy),
                        label: const Text('나이스 예외 TSV 복사'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _exportXlsx(ledger),
                        icon: const Icon(Icons.table_view),
                        label: const Text('엑셀로 공유'),
                      ),
                    ),
                  ],
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

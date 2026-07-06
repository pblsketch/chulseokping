import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../core/result/result.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/class_room.dart';
import '../../domain/value_objects/session_type.dart';
import '../shared/auth_controller.dart';
import '../shared/roster_providers.dart';

/// 교사 홈 — 학급 목록 + 세션 시작 (TE-1) + 학급 관리 (M6).
class TeacherShell extends ConsumerWidget {
  const TeacherShell({super.key});

  /// M6: 학급 생성은 create_class Edge Function 경유 — QR secret이 함께 발급된다.
  Future<void> _createClass(BuildContext context, WidgetRef ref) async {
    final name = await _promptClassName(context, title: '학급 만들기');
    if (name == null || !context.mounted) return;

    final result = await ref.read(createClassProvider).call(name);
    if (!context.mounted) return;
    switch (result) {
      case Ok(:final value):
        ref.invalidate(myClassesProvider);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('"${value.name}" 학급이 만들어졌어요')));
      case Err(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _renameClass(
    BuildContext context,
    WidgetRef ref,
    ClassRoom classRoom,
  ) async {
    final name = await _promptClassName(
      context,
      title: '학급 이름 변경',
      initial: classRoom.name,
    );
    if (name == null || !context.mounted) return;

    final result = await ref
        .read(renameClassProvider)
        .call(classId: classRoom.id, name: name);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        ref.invalidate(myClassesProvider);
      case Err(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _archiveClass(
    BuildContext context,
    WidgetRef ref,
    ClassRoom classRoom,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('학급 보관'),
        content: Text(
          '"${classRoom.name}" 학급을 보관할까요?\n\n'
          '학년도 종료·폐급용이에요. 세션과 출결 이력은 그대로 보존되고, '
          '학급 목록에서만 사라져요.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('보관'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref.read(archiveClassProvider).call(classRoom.id);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        ref.invalidate(myClassesProvider);
      case Err(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<String?> _promptClassName(
    BuildContext context, {
    required String title,
    String? initial,
  }) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(
            labelText: '학급 이름',
            hintText: '예: 1학년 3반',
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _startSession(
    BuildContext context,
    WidgetRef ref,
    ClassRoom classRoom,
  ) async {
    final choice = await showModalBottomSheet<_SessionStartChoice>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _SessionTypeSheet(),
    );
    if (choice == null || !context.mounted) return;

    final result = await ref
        .read(startSessionProvider)
        .call(
          classId: classRoom.id,
          type: choice.type,
          period: choice.period,
          windowMinutes: choice.windowMinutes,
          lateEnabled: choice.lateEnabled,
        );
    if (!context.mounted) return;
    switch (result) {
      case Ok(:final value):
        context.go('/teacher/session/${value.id}?classId=${classRoom.id}');
      case Err(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  /// KO-1: 기기 토큰 발급 — 토큰은 이 다이얼로그에서만 노출된다.
  Future<void> _issueKioskDevice(
    BuildContext context,
    WidgetRef ref,
    ClassRoom classRoom,
  ) async {
    final result = await ref.read(issueKioskDeviceProvider).call(classRoom.id);
    if (!context.mounted) return;
    switch (result) {
      case Ok(:final value):
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('키오스크 기기 발급'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '교실 태블릿의 "키오스크 모드"에서 이 토큰을 입력하세요.\n'
                  '토큰은 지금만 표시돼요 — 분실 시 재발급하세요.',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: AppSpacing.lg),
                SelectableText(
                  value.deviceToken,
                  style: AppTypography.mono.copyWith(fontSize: 20),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '비컨 major: ${value.beaconMajor}',
                  style: AppTypography.caption,
                ),
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
    final classes = ref.watch(myClassesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('출석핑 · 교사'),
        actions: [
          IconButton(
            tooltip: '학급 만들기',
            onPressed: () => _createClass(context, ref),
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: '로그아웃',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: classes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('$error', style: AppTypography.body)),
        data: (list) => list.isEmpty
            ? const Center(
                child: Text('학급이 아직 없어요', style: AppTypography.title),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: list.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final classRoom = list[index];
                  return Card(
                    child: ListTile(
                      title: Text(classRoom.name, style: AppTypography.title),
                      subtitle: Text(
                        '초대코드 ${classRoom.inviteCode}',
                        style: AppTypography.caption,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PopupMenuButton<String>(
                            tooltip: '학급 메뉴',
                            onSelected: (action) {
                              final query =
                                  '?name=${Uri.encodeComponent(classRoom.name)}';
                              switch (action) {
                                case 'roster':
                                  context.push(
                                    '/teacher/roster/${classRoom.id}$query',
                                  );
                                case 'ledger':
                                  context.push(
                                    '/teacher/ledger/${classRoom.id}$query',
                                  );
                                case 'kiosk':
                                  _issueKioskDevice(context, ref, classRoom);
                                case 'rename':
                                  _renameClass(context, ref, classRoom);
                                case 'archive':
                                  _archiveClass(context, ref, classRoom);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'roster',
                                child: Text('명단 관리 (동의·PIN)'),
                              ),
                              PopupMenuItem(
                                value: 'ledger',
                                child: Text('월별 일람표·나이스 내보내기'),
                              ),
                              PopupMenuItem(
                                value: 'kiosk',
                                child: Text('키오스크 기기 발급'),
                              ),
                              PopupMenuItem(
                                value: 'rename',
                                child: Text('학급 이름 변경'),
                              ),
                              PopupMenuItem(
                                value: 'archive',
                                child: Text('학급 보관 (학년도 종료)'),
                              ),
                            ],
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          FilledButton.icon(
                            onPressed: () =>
                                _startSession(context, ref, classRoom),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('세션 시작'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

typedef _SessionStartChoice = ({
  SessionType type,
  int? period,
  int? windowMinutes,
  bool lateEnabled,
});

class _SessionTypeSheet extends StatefulWidget {
  const _SessionTypeSheet();

  @override
  State<_SessionTypeSheet> createState() => _SessionTypeSheetState();
}

class _SessionTypeSheetState extends State<_SessionTypeSheet> {
  /// P0-1 수집 시간 기본 10분 (대학 데팍토 표준). null = 수동 종료(현행 동작).
  int? _windowMinutes = 10;
  bool _lateEnabled = false;

  void _pop(BuildContext context, SessionType type, int? period) {
    Navigator.pop(context, (
      type: type,
      period: period,
      windowMinutes: _windowMinutes,
      lateEnabled: _lateEnabled,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('출석 수집 시간', style: AppTypography.bodyStrong),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final (minutes, label) in [
                  (5, '5분'),
                  (10, '10분'),
                  (15, '15분'),
                  (null, '수동 종료'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _windowMinutes == minutes,
                    onSelected: (_) => setState(() {
                      _windowMinutes = minutes;
                      if (minutes == null) _lateEnabled = false;
                    }),
                  ),
              ],
            ),
            SwitchListTile(
              value: _lateEnabled,
              // 지각 판정 기준(N분)은 학교장 재량 사항 — 기본 off
              onChanged: _windowMinutes == null
                  ? null
                  : (v) => setState(() => _lateEnabled = v),
              contentPadding: EdgeInsets.zero,
              title: const Text('시간 이후는 지각으로 기록', style: AppTypography.body),
              subtitle: Text(
                _windowMinutes == null
                    ? '수동 종료에서는 쓸 수 없어요'
                    : '이후 20분 동안 지각으로 더 받아요 (사유는 나중에 확정)',
                style: AppTypography.caption,
              ),
            ),
            const Divider(height: AppSpacing.lg),
            const Text('세션 유형', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => _pop(context, SessionType.homeroom, null),
              child: const Text('조회 (담임)'),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('교시 (교과)', style: AppTypography.bodyStrong),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (var period = 1; period <= 7; period++)
                  ActionChip(
                    backgroundColor: AppColors.bgSubtle,
                    label: Text('$period교시'),
                    onPressed: () => _pop(context, SessionType.period, period),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

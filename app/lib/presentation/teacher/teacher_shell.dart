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

/// 교사 홈 — 학급 목록 + 세션 시작 (TE-1).
class TeacherShell extends ConsumerWidget {
  const TeacherShell({super.key});

  Future<void> _startSession(
    BuildContext context,
    WidgetRef ref,
    ClassRoom classRoom,
  ) async {
    final choice =
        await showModalBottomSheet<({SessionType type, int? period})>(
          context: context,
          builder: (context) => const _SessionTypeSheet(),
        );
    if (choice == null || !context.mounted) return;

    final result = await ref
        .read(startSessionProvider)
        .call(classId: classRoom.id, type: choice.type, period: choice.period);
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
                          IconButton(
                            tooltip: '키오스크 기기 발급',
                            onPressed: () =>
                                _issueKioskDevice(context, ref, classRoom),
                            icon: const Icon(Icons.tablet_android),
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

class _SessionTypeSheet extends StatelessWidget {
  const _SessionTypeSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('세션 유형', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, (
                type: SessionType.homeroom,
                period: null,
              )),
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
                    onPressed: () => Navigator.pop(context, (
                      type: SessionType.period,
                      period: period,
                    )),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

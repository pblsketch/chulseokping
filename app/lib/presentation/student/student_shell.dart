import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../shared/auth_controller.dart';
import '../shared/roster_providers.dart';

/// 학생 홈 — 활성 세션 감지 + QR 출석 (ST-4). BLE 자동 출석은 M3.
class StudentShell extends ConsumerWidget {
  const StudentShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classes = ref.watch(myClassesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('출석핑 · 학생'),
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
        error: (error, _) => Center(child: Text('$error')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('아직 소속 학급이 없어요', style: AppTypography.title),
            );
          }
          // v1: 학생은 보통 1개 학급 — 첫 학급 기준으로 표시
          final classRoom = list.first;
          final session = ref.watch(activeSessionProvider(classRoom.id));
          return RefreshIndicator(
            onRefresh: () async =>
                ref.refresh(activeSessionProvider(classRoom.id).future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text(classRoom.name, style: AppTypography.h1),
                const SizedBox(height: AppSpacing.xl),
                session.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Text('$error'),
                  data: (active) => active == null
                      ? const _NoSessionCard()
                      : _ActiveSessionCard(
                          sessionId: active.id,
                          label: active.period == null
                              ? '조회'
                              : '${active.period}교시',
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NoSessionCard extends StatelessWidget {
  const _NoSessionCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const Icon(
              Icons.wifi_tethering,
              size: AppSpacing.xxxl,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('아직 세션이 없어요', style: AppTypography.title),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              '선생님이 세션을 시작하면 여기에 떠요 · 아래로 당겨 새로고침',
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveSessionCard extends StatelessWidget {
  const _ActiveSessionCard({required this.sessionId, required this.label});

  final String sessionId;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const Icon(
              Icons.wifi_tethering,
              size: AppSpacing.xxxl,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('$label 세션 진행 중', style: AppTypography.title),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () =>
                  context.push('/student/scan?sessionId=$sessionId'),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('QR 스캔으로 출석'),
            ),
          ],
        ),
      ),
    );
  }
}

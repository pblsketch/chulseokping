import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/device_identity.dart';
import '../shared/auth_controller.dart';
import '../shared/roster_providers.dart';
import 'ble_check_in_controller.dart';

/// 본인의 세션 출석 기록 (Realtime) — QR/BLE/키오스크 어느 경로든 즉시 반영.
final myAttendanceProvider = StreamProvider.autoDispose
    .family<AttendanceRecord?, String>(
      (ref, sessionId) => ref.watch(watchMyAttendanceProvider).call(sessionId),
    );

/// P0-2: 로그인 후 기기 등록/확인 — 실패는 조용히 null (출석 흐름을 막지 않는다).
/// autoDispose: 로그아웃으로 셸이 내려가면 다음 로그인 때 새로 등록한다.
final deviceRegistrationProvider = FutureProvider.autoDispose<DeviceIdentity?>((
  ref,
) async {
  final result = await ref.watch(ensureDeviceRegisteredProvider).call();
  return result.fold((identity) => identity, (_) => null);
});

/// 학생 홈 — 활성 세션 감지 + QR 출석 (ST-4). BLE 자동 출석은 M3.
class StudentShell extends ConsumerWidget {
  const StudentShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classes = ref.watch(myClassesProvider);
    // 기기 등록은 셸 진입 시 1회 — pending이면 안내 배너만 (출석은 계속 가능)
    final device = ref.watch(deviceRegistrationProvider).value;

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
            // Realtime 구독이라 보통은 자동 갱신되지만, 재연결이 필요한 경우를 위해 남겨둠.
            onRefresh: () async =>
                ref.invalidate(activeSessionProvider(classRoom.id)),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text(classRoom.name, style: AppTypography.h1),
                if (device?.isPending ?? false) ...[
                  const SizedBox(height: AppSpacing.md),
                  const _PendingDeviceBanner(),
                ],
                const SizedBox(height: AppSpacing.xl),
                session.when(
                  loading: () => const _LoadingCard(),
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

/// P0-2: 새 기기 승인 대기 안내 — 차단이 아니라 안내다 (색만으로 전달 금지, 텍스트 병기).
class _PendingDeviceBanner extends StatelessWidget {
  const _PendingDeviceBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.phonelink_lock, size: 18, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '새 기기예요 — 선생님 승인을 기다리고 있어요',
              style: AppTypography.caption.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(height: AppSpacing.lg),
            Text('세션 확인 중...', style: AppTypography.caption),
          ],
        ),
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

class _ActiveSessionCard extends ConsumerStatefulWidget {
  const _ActiveSessionCard({required this.sessionId, required this.label});

  final String sessionId;
  final String label;

  @override
  ConsumerState<_ActiveSessionCard> createState() => _ActiveSessionCardState();
}

class _ActiveSessionCardState extends ConsumerState<_ActiveSessionCard> {
  @override
  void initState() {
    super.initState();
    // ST-2/ST-3: 세션이 뜨면 비컨 감지 시작 (실패 시 QR 폴백 안내)
    Future.microtask(
      () => ref
          .read(bleCheckInControllerProvider(widget.sessionId).notifier)
          .start(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bleState = ref.watch(bleCheckInControllerProvider(widget.sessionId));
    // 서버 기록이 진실 원천 — QR/키오스크로 출석해도 홈이 즉시 "출석됨"으로 바뀐다.
    final myRecord = ref.watch(myAttendanceProvider(widget.sessionId));
    final checkedIn = bleState is BleSuccess || myRecord.value != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(
              checkedIn ? Icons.check_circle : Icons.wifi_tethering,
              size: AppSpacing.xxxl,
              color: checkedIn ? AppColors.success : AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('${widget.label} 세션 진행 중', style: AppTypography.title),
            const SizedBox(height: AppSpacing.lg),
            if (checkedIn)
              Text(
                '출석되었어요!',
                style: AppTypography.bodyStrong.copyWith(
                  color: AppColors.success,
                ),
              )
            else ...[
              _BleStatusArea(sessionId: widget.sessionId, state: bleState),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: () =>
                    context.push('/student/scan?sessionId=${widget.sessionId}'),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('QR 스캔으로 출석'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// BLE 상태 표시 — 색만으로 전달하지 않고 항상 텍스트 병기 (design.md).
class _BleStatusArea extends ConsumerWidget {
  const _BleStatusArea({required this.sessionId, required this.state});

  final String sessionId;
  final BleCheckInState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (state) {
      BleIdle() => const SizedBox.shrink(),
      BleScanning() => const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: AppSpacing.sm),
          Text('교실 비컨(핑) 감지 중...', style: AppTypography.caption),
        ],
      ),
      BleDetected() => ElevatedButton.icon(
        onPressed: () => ref
            .read(bleCheckInControllerProvider(sessionId).notifier)
            .confirm(),
        icon: const Icon(Icons.wifi_tethering),
        label: const Text('핑! 감지됨 — 탭해서 출석'),
      ),
      BleSubmitting() => const Text('출석 처리 중...', style: AppTypography.caption),
      BleSuccess() => Text(
        '자동 출석되었어요!',
        style: AppTypography.bodyStrong.copyWith(color: AppColors.success),
      ),
      BleNotFound() => Column(
        children: [
          Text(
            '교실 비컨을 찾지 못했어요 — QR로 출석해 주세요',
            style: AppTypography.caption.copyWith(color: AppColors.warning),
            textAlign: TextAlign.center,
          ),
          TextButton.icon(
            onPressed: () => ref
                .read(bleCheckInControllerProvider(sessionId).notifier)
                .retry(),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('다시 감지'),
          ),
        ],
      ),
      BleFailed(:final message) || BleUnavailable(:final message) => Text(
        message,
        style: AppTypography.caption.copyWith(color: AppColors.warning),
        textAlign: TextAlign.center,
      ),
    };
  }
}

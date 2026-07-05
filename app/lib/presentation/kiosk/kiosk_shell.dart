import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/kiosk_lock.dart';
import '../../core/utils/rotating_code.dart';
import '../../domain/entities/kiosk_sync.dart';
import 'kiosk_controller.dart';

/// 키오스크 셸 (KO-1/2/3/6) — 원거리 가독·단일 동작 (design.md §0).
/// 화면 고정은 소프트(screen pinning) — 완전 잠금 아님, 교사 근접 권고.
class KioskShell extends ConsumerStatefulWidget {
  const KioskShell({super.key});

  @override
  ConsumerState<KioskShell> createState() => _KioskShellState();
}

class _KioskShellState extends ConsumerState<KioskShell> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    KioskLock.enable(); // 실패해도 계속 동작 (소프트 고정)
  }

  @override
  void dispose() {
    KioskLock.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _confirmUnregister() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기기 등록 해제'),
        content: const Text('이 태블릿의 키오스크 등록을 해제할까요?\n(교사만 수행하세요)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('해제'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(kioskControllerProvider.notifier).unregister();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kioskControllerProvider);
    return PopScope(
      canPop: false, // 이탈 방지 (KO-6 소프트)
      child: Scaffold(
        backgroundColor: AppColors.bgSubtle,
        body: SafeArea(
          child: state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('$error')),
            data: (kiosk) => switch (kiosk) {
              KioskUnregistered() => const _RegisterView(),
              KioskReady(:final sync, :final deviceToken) => _ReadyView(
                sync: sync,
                deviceToken: deviceToken,
                onUnregister: _confirmUnregister,
              ),
            },
          ),
        ),
      ),
    );
  }
}

/// KO-1: 기기 토큰 입력.
class _RegisterView extends ConsumerStatefulWidget {
  const _RegisterView();

  @override
  ConsumerState<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<_RegisterView> {
  final _tokenController = TextEditingController();
  String? _errorMessage;
  bool _submitting = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    final failure = await ref
        .read(kioskControllerProvider.notifier)
        .register(_tokenController.text);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _errorMessage = failure?.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '키오스크 등록',
                style: AppTypography.display,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                '선생님이 발급한 기기 토큰을 입력하세요',
                style: AppTypography.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _tokenController,
                style: AppTypography.mono,
                decoration: const InputDecoration(
                  labelText: '기기 토큰',
                  hintText: 'kp-XXXXXXXXXXXXXXXX',
                ),
                onSubmitted: (_) => _register(),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _errorMessage!,
                  style: AppTypography.body.copyWith(color: AppColors.danger),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: _submitting ? null : _register,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('등록'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadyView extends ConsumerWidget {
  const _ReadyView({
    required this.sync,
    required this.deviceToken,
    required this.onUnregister,
  });

  final KioskSyncState sync;
  final String deviceToken;
  final Future<void> Function() onUnregister;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = sync.activeSession;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Text(sync.className, style: AppTypography.h1),
              const Spacer(),
              if (session != null)
                Text('${session.label} 진행 중', style: AppTypography.title),
              IconButton(
                tooltip: '기기 설정',
                onPressed: onUnregister,
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
        ),
        Expanded(
          child: session == null
              ? const _WaitingView()
              : _ActiveView(
                  sync: sync,
                  session: session,
                  deviceToken: deviceToken,
                ),
        ),
      ],
    );
  }
}

class _WaitingView extends StatelessWidget {
  const _WaitingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.hourglass_empty,
            size: AppSpacing.xxxl * 2,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            '세션 대기 중',
            style: AppTypography.display.copyWith(
              fontSize:
                  AppTypography.display.fontSize! * AppTypography.kioskScale,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('선생님이 세션을 시작하면 QR이 표시돼요', style: AppTypography.title),
        ],
      ),
    );
  }
}

/// KO-2 회전 QR(특대) + KO-4 PIN 진입.
class _ActiveView extends StatefulWidget {
  const _ActiveView({
    required this.sync,
    required this.session,
    required this.deviceToken,
  });

  final KioskSyncState sync;
  final KioskSession session;
  final String deviceToken;

  @override
  State<_ActiveView> createState() => _ActiveViewState();
}

class _ActiveViewState extends State<_ActiveView> {
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
    final qrSecret = widget.sync.qrSecret;
    final now = DateTime.now().millisecondsSinceEpoch;
    final remaining = RotatingCode.remainingMs(now);
    final fraction = remaining / (RotatingCode.periodSeconds * 1000);

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Center(
            child: qrSecret == null
                ? const Text('QR 설정을 불러올 수 없어요', style: AppTypography.title)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.bgBase,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                        ),
                        child: QrImageView(
                          data: jsonEncode({
                            'v': 1,
                            'sid': widget.session.id,
                            'c': RotatingCode.totpCode(
                              qrSecret,
                              timestampMs: now,
                            ),
                          }),
                          size: 360,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: 360,
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 6,
                          color: fraction < 0.25
                              ? AppColors.warning
                              : AppColors.primary,
                          backgroundColor: AppColors.borderDefault,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text('QR을 스캔하면 출석돼요', style: AppTypography.h2),
                    ],
                  ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.dialpad,
                    size: AppSpacing.xxxl,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    '폰이 없나요?',
                    style: AppTypography.h2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    height: AppSpacing.touchTargetKiosk,
                    child: ElevatedButton(
                      onPressed: () => context.push(
                        '/kiosk/pin?sessionId=${widget.session.id}'
                        '&deviceToken=${widget.deviceToken}',
                      ),
                      child: const Text('학번 + PIN으로 출석'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

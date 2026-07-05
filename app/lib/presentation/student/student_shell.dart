import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// 학생앱 셸 — M1에서 QR 스캔, M3에서 BLE 감지가 얹힌다.
class StudentShell extends StatelessWidget {
  const StudentShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('출석핑 · 학생')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_tethering,
              size: AppSpacing.xxxl,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('아직 세션이 없어요', style: AppTypography.title),
            const SizedBox(height: AppSpacing.sm),
            const Text('선생님이 세션을 시작하면 여기에 떠요', style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}

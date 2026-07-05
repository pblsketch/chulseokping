import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// 키오스크 셸 — M2에서 회전 QR·PIN 패드·화면 고정이 얹힌다.
/// design.md: 원거리 가독(특대 폰트 ×1.6), 단일 동작, 오조작 방지.
class KioskShell extends StatelessWidget {
  const KioskShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSubtle,
      body: Center(
        child: MediaQuery.withClampedTextScaling(
          minScaleFactor: AppTypography.kioskScale,
          maxScaleFactor: AppTypography.kioskScale,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.qr_code_2,
                size: AppSpacing.xxxl * 2,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text('키오스크 준비 중', style: AppTypography.display),
              const SizedBox(height: AppSpacing.md),
              const Text('기기 등록 후 세션을 시작하세요', style: AppTypography.body),
            ],
          ),
        ),
      ),
    );
  }
}

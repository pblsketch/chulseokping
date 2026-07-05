import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// 교사 대시보드 셸 — M1에서 세션 시작·실시간 현황·수동 수정이 얹힌다.
class TeacherShell extends StatelessWidget {
  const TeacherShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('출석핑 · 교사')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.dashboard_outlined,
              size: AppSpacing.xxxl,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('학급이 아직 없어요', style: AppTypography.title),
            const SizedBox(height: AppSpacing.sm),
            const Text('학급을 만들고 첫 세션을 시작해 보세요', style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}

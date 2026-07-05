import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// M0 스캐폴드 진입 화면 — M1에서 Supabase Auth 로그인으로 교체.
class RoleSelectPage extends ConsumerWidget {
  const RoleSelectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void enter(AppRole role, String path) {
      ref.read(appRoleProvider.notifier).set(role);
      context.go(path);
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '출석핑',
                style: AppTypography.display,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                '비컨이 "핑" 하면 자동 출석',
                style: AppTypography.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton(
                onPressed: () => enter(AppRole.student, '/student'),
                child: const Text('학생으로 시작'),
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => enter(AppRole.teacher, '/teacher'),
                child: const Text('교사로 시작'),
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => enter(AppRole.kiosk, '/kiosk'),
                child: const Text('키오스크 모드'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

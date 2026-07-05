import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/value_objects/attendance_status.dart';

/// 출결 상태 칩 — 색 + 한글 라벨 병기 (design.md: 색만으로 전달 금지).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, this.status});

  /// null = 미출석(기록 없음)
  final AttendanceStatus? status;

  Color get _color => switch (status) {
    AttendanceStatus.present => AppColors.statusPresent,
    AttendanceStatus.late_ => AppColors.statusLate,
    AttendanceStatus.earlyLeave => AppColors.statusEarlyLeave,
    AttendanceStatus.classAbsent ||
    AttendanceStatus.absent => AppColors.statusAbsent,
    null => AppColors.textDisabled,
  };

  @override
  Widget build(BuildContext context) {
    final label = status?.label ?? '미출석';
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: _color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

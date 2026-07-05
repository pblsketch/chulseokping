import 'package:flutter/material.dart';

/// design.md §1 컬러 토큰. 매직 값 금지 — 모든 색은 여기서 참조한다.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF2E6BE6); // 신호·핑 블루 (CTA, 활성)
  static const Color primaryHover = Color(0xFF1F57C2);
  static const Color accent = Color(0xFF18B6A6);

  // Neutral (밝은 베이스)
  static const Color bgBase = Color(0xFFFFFFFF);
  static const Color bgSubtle = Color(0xFFF6F8FB);
  static const Color bgElevated = Color(0xFFFFFFFF);
  static const Color borderDefault = Color(0xFFE4E8EF);
  static const Color textPrimary = Color(0xFF1A1F29);
  static const Color textSecondary = Color(0xFF5B6472);
  static const Color textDisabled = Color(0xFF9AA3B2);

  // 출결 상태색 (색만으로 전달 금지 — 항상 한글 라벨 병기)
  static const Color statusPresent = Color(0xFF2BB673);
  static const Color statusLate = Color(0xFFE8A53D);
  static const Color statusEarlyLeave = Color(0xFF6C8AE4);
  static const Color statusAbsent = Color(0xFFE5564E); // 결석/결과

  // Feedback
  static const Color success = Color(0xFF2BB673);
  static const Color warning = Color(0xFFE8A53D);
  static const Color danger = Color(0xFFE5564E);
  static const Color info = Color(0xFF2E6BE6);
}

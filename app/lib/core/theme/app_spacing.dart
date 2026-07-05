import 'package:flutter/animation.dart';

/// design.md §3·§5 스페이싱/형태/모션 토큰.
abstract final class AppSpacing {
  // 4 기반 스케일
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // 라운딩
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusPill = 999;

  // 터치 타깃 최소 (키오스크는 64)
  static const double touchTarget = 48;
  static const double touchTargetKiosk = 64;
}

/// design.md §5 모션 토큰.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration emphasized = Duration(milliseconds: 300);
  static const Curve ease = Cubic(0.2, 0, 0, 1);
}

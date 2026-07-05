import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 회귀 가드: dchs_flutter_beacon 0.6.9의 checkLocationServicesPermission()은
/// API31+에서도 neverForLocation과 무관하게 ACCESS_FINE_LOCATION 승인 여부를 확인한다.
/// 이 권한에 maxSdkVersion을 다시 걸면 API31+ 기기에서 권한 선언 자체가 사라져
/// 승인이 영원히 불가능해지고 비컨 스캔이 "항상 불가"로 고정된다 (2026-07-06 실기 회귀).
void main() {
  test('AndroidManifest: ACCESS_FINE_LOCATION에 maxSdkVersion 제한이 없다', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    // 주석 안에도 "ACCESS_FINE_LOCATION"·"maxSdkVersion"이 설명용으로 등장하므로
    // 실제 <uses-permission> 태그 줄만 골라야 한다.
    final line = manifest
        .split('\n')
        .firstWhere(
          (l) =>
              l.trim().startsWith('<uses-permission') &&
              l.contains('ACCESS_FINE_LOCATION'),
        );
    expect(
      line.contains('maxSdkVersion'),
      isFalse,
      reason:
          'ACCESS_FINE_LOCATION은 모든 API 레벨에서 선언되어야 한다 — '
          'dchs_flutter_beacon이 API31+에서도 이 권한을 무조건 확인함',
    );
  });
}

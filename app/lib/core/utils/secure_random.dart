import 'dart:math';

/// 키오스크 기기 토큰·비컨 secret 생성 (Random.secure).
abstract final class SecureRandom {
  static final Random _random = Random.secure();

  static String hex(int byteLength) {
    final buffer = StringBuffer();
    for (var i = 0; i < byteLength; i++) {
      buffer.write(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  /// 기기 토큰 — 사람이 타이핑하므로 적당히 짧게(16 hex), 접두사로 식별
  static String deviceToken() => 'kp-${hex(8)}';

  /// HMAC secret (20 bytes = SHA-1 블록에 적합)
  static String beaconSecret() => hex(20);

  /// iBeacon major (1~65535)
  static int beaconMajor() => _random.nextInt(65535) + 1;
}

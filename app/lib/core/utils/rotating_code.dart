import 'package:crypto/crypto.dart';

/// 회전 코드(TOTP) — 서버 `_shared/totp.ts`와 동일 알고리즘 (HMAC-SHA1, hex secret).
/// 교차 검증 벡터 테스트로 두 구현의 일치를 고정한다 (test/core/rotating_code_test.dart).
/// 표시(교사 회전 QR) 전용 — 검증은 항상 서버(Edge Function)가 한다.
abstract final class RotatingCode {
  static const int periodSeconds = 5; // PRD KO-2

  static List<int> _hexToBytes(String hex) {
    if (hex.length % 2 != 0 || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex)) {
      throw ArgumentError('invalid hex secret');
    }
    return [
      for (var i = 0; i < hex.length; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16),
    ];
  }

  static int _hotp(String secretHex, int counter) {
    final key = _hexToBytes(secretHex);
    final message = List<int>.filled(8, 0);
    var value = counter;
    for (var i = 7; i >= 0; i--) {
      message[i] = value & 0xff;
      value >>= 8;
    }
    final mac = Hmac(sha1, key).convert(message).bytes;
    final offset = mac[mac.length - 1] & 0x0f;
    return ((mac[offset] & 0x7f) << 24) |
        (mac[offset + 1] << 16) |
        (mac[offset + 2] << 8) |
        mac[offset + 3];
  }

  static int _counterOf(int timestampMs) =>
      (timestampMs ~/ 1000) ~/ periodSeconds;

  /// QR용 6자리 코드
  static String totpCode(
    String secretHex, {
    required int timestampMs,
    int digits = 6,
  }) {
    final value = _hotp(secretHex, _counterOf(timestampMs));
    return (value % 1000000).toString().padLeft(digits, '0');
  }

  /// BLE 회전 minor (16-bit)
  static int beaconMinor(String secretHex, {required int timestampMs}) =>
      _hotp(secretHex, _counterOf(timestampMs)) % 65536;

  /// 현재 period의 남은 시간(ms) — 회전 QR 잔여 링 표시용
  static int remainingMs(int timestampMs) =>
      periodSeconds * 1000 - (timestampMs % (periodSeconds * 1000));
}

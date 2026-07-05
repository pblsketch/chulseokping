import 'package:chulseokping_app/core/utils/secure_random.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deviceToken: kp- 접두 + 16 hex, 호출마다 다름', () {
    final a = SecureRandom.deviceToken();
    final b = SecureRandom.deviceToken();
    expect(a, matches(RegExp(r'^kp-[0-9a-f]{16}$')));
    expect(a == b, isFalse);
  });

  test('beaconSecret: 20바이트 hex (HMAC-SHA1 key)', () {
    expect(SecureRandom.beaconSecret(), matches(RegExp(r'^[0-9a-f]{40}$')));
  });

  test('beaconMajor: 1~65535 (iBeacon major 범위)', () {
    for (var i = 0; i < 100; i++) {
      final major = SecureRandom.beaconMajor();
      expect(major, inInclusiveRange(1, 65535));
    }
  });
}

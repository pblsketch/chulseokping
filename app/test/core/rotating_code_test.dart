import 'package:chulseokping_app/core/utils/rotating_code.dart';
import 'package:flutter_test/flutter_test.dart';

// 교차 검증 벡터 — supabase/functions/_shared/totp.ts(Deno)에서 생성.
// 두 구현이 갈라지면 회전 QR/BLE 검증이 통째로 깨지므로 이 테스트가 계약이다.
// 생성 명령: deno eval "import { totpCode, beaconMinor } from './supabase/functions/_shared/totp.ts'; ..."
const secret = '3132333435363738393031323334353637383930';

void main() {
  group('Deno 구현과의 교차 검증 (HMAC-SHA1, period 5s)', () {
    const vectors = [
      (ms: 1750000000000, code: '842715', minor: 27355),
      (ms: 1750000005000, code: '915708', minor: 17212),
      (ms: 1767225600000, code: '134199', minor: 1719),
      (ms: 1893456000000, code: '643568', minor: 47728),
    ];

    for (final v in vectors) {
      test('t=${v.ms}: code=${v.code}, minor=${v.minor}', () {
        expect(RotatingCode.totpCode(secret, timestampMs: v.ms), v.code);
        expect(RotatingCode.beaconMinor(secret, timestampMs: v.ms), v.minor);
      });
    }
  });

  test('잘못된 hex secret은 예외', () {
    expect(
      () => RotatingCode.totpCode('not-hex!!', timestampMs: 0),
      throwsArgumentError,
    );
  });

  test('remainingMs: period 경계에서 5000, 직전엔 1', () {
    expect(RotatingCode.remainingMs(1750000000000), 5000);
    expect(RotatingCode.remainingMs(1750000004999), 1);
  });
}

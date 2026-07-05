// TOTP 단위 테스트 — PRD §13: ±5s 경계, 잘못된 secret, minor 16-bit 접기.
import { assert, assertEquals, assertFalse, assertRejects } from "jsr:@std/assert@1";
import { beaconMinor, totpCode, verifyBeaconMinor, verifyTotpCode } from "./totp.ts";

// RFC 6238 테스트 키 "12345678901234567890"의 hex
const SECRET = "3132333435363738393031323334353637383930";
const OTHER_SECRET = "aabbccddeeff00112233445566778899aabbccdd";
const T0 = 1_750_000_000_000; // 고정 기준 시각(ms)

Deno.test("totpCode: 6자리, 같은 period 내 동일, period 넘으면 변경", async () => {
  const a = await totpCode(SECRET, { timestampMs: T0 });
  const b = await totpCode(SECRET, { timestampMs: T0 + 4_000 }); // 같은 5s 스텝 보장 위해 T0가 스텝 경계
  assertEquals(a.length, 6);
  // T0는 5초 스텝 경계(1_750_000_000 % 5 == 0) → +4s는 같은 스텝
  assertEquals(a, b);
  const c = await totpCode(SECRET, { timestampMs: T0 + 5_000 });
  assert(a !== c, "다음 스텝에서는 코드가 바뀌어야 함");
});

Deno.test("verifyTotpCode: 정시 유효 + window=1로 ±5s 경계 유효", async () => {
  const code = await totpCode(SECRET, { timestampMs: T0 });
  assert(await verifyTotpCode(SECRET, code, { timestampMs: T0, window: 1 }));
  assert(await verifyTotpCode(SECRET, code, { timestampMs: T0 + 5_000, window: 1 }));
  assert(await verifyTotpCode(SECRET, code, { timestampMs: T0 - 5_000, window: 1 }));
});

Deno.test("verifyTotpCode: ±10s(2스텝)는 만료", async () => {
  const code = await totpCode(SECRET, { timestampMs: T0 });
  assertFalse(await verifyTotpCode(SECRET, code, { timestampMs: T0 + 10_000, window: 1 }));
  assertFalse(await verifyTotpCode(SECRET, code, { timestampMs: T0 - 10_000, window: 1 }));
});

Deno.test("verifyTotpCode: 다른 secret이면 거부", async () => {
  const code = await totpCode(SECRET, { timestampMs: T0 });
  assertFalse(await verifyTotpCode(OTHER_SECRET, code, { timestampMs: T0, window: 1 }));
});

Deno.test("잘못된 hex secret은 예외", async () => {
  await assertRejects(() => totpCode("not-hex!!", { timestampMs: T0 }));
});

Deno.test("beaconMinor: 0~65535 범위 + 스텝마다 회전", async () => {
  const m0 = await beaconMinor(SECRET, { timestampMs: T0 });
  assert(m0 >= 0 && m0 <= 65535);
  const m1 = await beaconMinor(SECRET, { timestampMs: T0 + 5_000 });
  assert(m0 !== m1, "다음 스텝에서 minor가 회전해야 함");
});

Deno.test("verifyBeaconMinor: 정시·±1스텝 유효, 2스텝 만료, 범위 밖 거부", async () => {
  const minor = await beaconMinor(SECRET, { timestampMs: T0 });
  assert(await verifyBeaconMinor(SECRET, minor, { timestampMs: T0, window: 1 }));
  assert(await verifyBeaconMinor(SECRET, minor, { timestampMs: T0 + 5_000, window: 1 }));
  assertFalse(await verifyBeaconMinor(SECRET, minor, { timestampMs: T0 + 10_000, window: 1 }));
  assertFalse(await verifyBeaconMinor(SECRET, 70_000, { timestampMs: T0, window: 1 }));
  assertFalse(await verifyBeaconMinor(SECRET, -1, { timestampMs: T0, window: 1 }));
});

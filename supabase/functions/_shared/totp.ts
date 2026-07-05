// TOTP (RFC 6238 변형) — 출석핑 회전 QR·BLE 회전 minor 공용.
// period 기본 5초. secret은 hex 문자열(HMAC-SHA1 key).
// banha qr.ts의 검증 컨셉 이식(로직 재작성).

const encoderCache: Record<string, CryptoKey> = {};

function hexToBytes(hex: string): Uint8Array {
  if (!/^[0-9a-fA-F]+$/.test(hex) || hex.length % 2 !== 0) {
    throw new Error("invalid hex secret");
  }
  const out = new Uint8Array(hex.length / 2);
  for (let i = 0; i < out.length; i++) {
    out[i] = parseInt(hex.slice(i * 2, i * 2 + 2), 16);
  }
  return out;
}

async function importKey(secretHex: string): Promise<CryptoKey> {
  if (!encoderCache[secretHex]) {
    encoderCache[secretHex] = await crypto.subtle.importKey(
      "raw",
      hexToBytes(secretHex).buffer as ArrayBuffer,
      { name: "HMAC", hash: "SHA-1" },
      false,
      ["sign"],
    );
  }
  return encoderCache[secretHex];
}

/** HOTP 코어: counter → 31-bit 동적 절단 값 */
export async function hotp(secretHex: string, counter: number): Promise<number> {
  const key = await importKey(secretHex);
  const buf = new ArrayBuffer(8);
  new DataView(buf).setBigUint64(0, BigInt(counter));
  const mac = new Uint8Array(await crypto.subtle.sign("HMAC", key, buf));
  const offset = mac[mac.length - 1] & 0x0f;
  return (
    ((mac[offset] & 0x7f) << 24) |
    (mac[offset + 1] << 16) |
    (mac[offset + 2] << 8) |
    mac[offset + 3]
  );
}

export interface TotpOptions {
  periodSeconds?: number; // 기본 5초 (PRD KO-2/BE-1)
  digits?: number; // QR 코드 자릿수, 기본 6
  timestampMs?: number; // 기본 현재 시각 (테스트 주입용)
}

function counterOf(timestampMs: number, periodSeconds: number): number {
  return Math.floor(timestampMs / 1000 / periodSeconds);
}

/** QR용 TOTP 코드(숫자 문자열, digits 자리) */
export async function totpCode(secretHex: string, opts: TotpOptions = {}): Promise<string> {
  const { periodSeconds = 5, digits = 6, timestampMs = Date.now() } = opts;
  const value = await hotp(secretHex, counterOf(timestampMs, periodSeconds));
  return (value % 10 ** digits).toString().padStart(digits, "0");
}

/** QR TOTP 검증 — window=1이면 ±1 스텝(±period초) 허용 (BE-1: ±5s) */
export async function verifyTotpCode(
  secretHex: string,
  code: string,
  opts: TotpOptions & { window?: number } = {},
): Promise<boolean> {
  const { periodSeconds = 5, digits = 6, timestampMs = Date.now(), window = 1 } = opts;
  const base = counterOf(timestampMs, periodSeconds);
  for (let w = -window; w <= window; w++) {
    const value = await hotp(secretHex, base + w);
    const expected = (value % 10 ** digits).toString().padStart(digits, "0");
    if (expected === code) return true;
  }
  return false;
}

/** BLE 회전 minor: TOTP 값을 16-bit 공간으로 접음 (iBeacon minor 규격) */
export async function beaconMinor(
  secretHex: string,
  opts: TotpOptions = {},
): Promise<number> {
  const { periodSeconds = 5, timestampMs = Date.now() } = opts;
  const value = await hotp(secretHex, counterOf(timestampMs, periodSeconds));
  return value % 65536;
}

/** BLE 회전 minor 검증 — window 스텝 허용 (BE-3) */
export async function verifyBeaconMinor(
  secretHex: string,
  minor: number,
  opts: TotpOptions & { window?: number } = {},
): Promise<boolean> {
  const { periodSeconds = 5, timestampMs = Date.now(), window = 1 } = opts;
  if (!Number.isInteger(minor) || minor < 0 || minor > 65535) return false;
  const base = counterOf(timestampMs, periodSeconds);
  for (let w = -window; w <= window; w++) {
    const value = await hotp(secretHex, base + w);
    if (value % 65536 === minor) return true;
  }
  return false;
}

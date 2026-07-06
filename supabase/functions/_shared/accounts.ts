// M5 계정·온보딩 공통 (하이브리드 모델: 교사 일괄 생성 + 학생 연결 코드)
// 연결 코드 계약: 32자 알파벳(혼동 문자 I/O/0/1 제외) × 12자 = 60비트 엔트로피.
// DB에는 sha256 해시만 저장 — 평문은 발급 HTTP 응답에서 1회만 노출.

// 256 = 32 × 8 이라 바이트 modulo에 편향이 없다 (알파벳 크기를 바꾸면 재검토할 것)
const CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

export const LINK_CODE_LENGTH = 12;
export const LINK_CODE_TTL_HOURS = 48;

/** 학생 내부 계정 이메일 — 실제 수신 불가 도메인. 학생은 이 값을 알 필요가 없다. */
export function internalStudentEmail(): string {
  return `stu-${crypto.randomUUID()}@student.chulseokping.internal`;
}

export function generateLinkCode(): string {
  const bytes = new Uint8Array(LINK_CODE_LENGTH);
  crypto.getRandomValues(bytes);
  return Array.from(bytes)
    .map((b) => CODE_ALPHABET[b % CODE_ALPHABET.length])
    .join("");
}

/** 사용자 입력 정규화: 대문자화 + 구분자(공백/하이픈) 제거 */
export function normalizeLinkCode(input: string): string {
  return input.toUpperCase().replace(/[\s-]/g, "");
}

export function isValidLinkCodeFormat(code: string): boolean {
  return code.length === LINK_CODE_LENGTH &&
    [...code].every((ch) => CODE_ALPHABET.includes(ch));
}

/** 표시용 4자 단위 그룹핑 (ABCD-EFGH-JKLM) */
export function formatLinkCode(code: string): string {
  return code.match(/.{1,4}/g)?.join("-") ?? code;
}

export async function sha256Hex(text: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(text),
  );
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/** 학생 계정용 랜덤 비밀번호 — redeem 시마다 회전되므로 저장·기억 대상이 아니다. */
export function randomPassword(): string {
  const bytes = new Uint8Array(24);
  crypto.getRandomValues(bytes);
  return Array.from(bytes).map((b) => b.toString(16).padStart(2, "0")).join("");
}

/** 학급 표시용 초대코드 8자 (M5에서 로그인 용도는 연결 코드로 대체 — 표시·식별용) */
export function generateInviteCode(): string {
  const bytes = new Uint8Array(8);
  crypto.getRandomValues(bytes);
  return Array.from(bytes)
    .map((b) => CODE_ALPHABET[b % CODE_ALPHABET.length])
    .join("");
}

/** 학급 QR TOTP secret — 20바이트 hex (앱 SecureRandom.beaconSecret과 동일 계약) */
export function randomHexSecret(byteLength = 20): string {
  const bytes = new Uint8Array(byteLength);
  crypto.getRandomValues(bytes);
  return Array.from(bytes).map((b) => b.toString(16).padStart(2, "0")).join("");
}

export function linkCodeExpiry(now = new Date()): string {
  return new Date(now.getTime() + LINK_CODE_TTL_HOURS * 3600_000).toISOString();
}

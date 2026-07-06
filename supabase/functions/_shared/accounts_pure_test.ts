// 연결 코드 순수 로직 테스트 — deno test로 실행 (DB 불필요)
import {
  formatLinkCode,
  generateLinkCode,
  isValidLinkCodeFormat,
  LINK_CODE_LENGTH,
  linkCodeExpiry,
  normalizeLinkCode,
  sha256Hex,
} from "./accounts.ts";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

Deno.test("generateLinkCode: 길이·알파벳·유일성", () => {
  const seen = new Set<string>();
  for (let i = 0; i < 200; i++) {
    const code = generateLinkCode();
    assert(code.length === LINK_CODE_LENGTH, `길이 ${code.length}`);
    assert(isValidLinkCodeFormat(code), `형식 위반: ${code}`);
    assert(!/[IO01]/.test(code), `혼동 문자 포함: ${code}`);
    seen.add(code);
  }
  assert(seen.size === 200, "200회 생성에서 중복 발생 — 엔트로피 의심");
});

Deno.test("normalizeLinkCode: 소문자·공백·하이픈 허용", () => {
  const code = generateLinkCode();
  const display = formatLinkCode(code);
  assert(display.includes("-"), `그룹핑 없음: ${display}`);
  assert(normalizeLinkCode(display) === code, "표시형 → 원형 복원 실패");
  assert(
    normalizeLinkCode(` ${display.toLowerCase()} `) === code,
    "소문자+공백 정규화 실패",
  );
});

Deno.test("isValidLinkCodeFormat: 길이·문자 검증", () => {
  assert(!isValidLinkCodeFormat("SHORT"), "짧은 코드 통과");
  assert(!isValidLinkCodeFormat("ABCDEFGHJKL0"), "금지 문자 0 통과");
  assert(!isValidLinkCodeFormat(""), "빈 문자열 통과");
});

Deno.test("sha256Hex: 결정적 64자 hex", async () => {
  const a = await sha256Hex("ABCD2345EFGH");
  const b = await sha256Hex("ABCD2345EFGH");
  assert(a === b, "동일 입력 다른 해시");
  assert(/^[0-9a-f]{64}$/.test(a), `hex 형식 아님: ${a}`);
});

Deno.test("linkCodeExpiry: 48시간 후", () => {
  const now = new Date("2026-07-06T00:00:00Z");
  assert(
    linkCodeExpiry(now) === "2026-07-08T00:00:00.000Z",
    `만료 시각 오류: ${linkCodeExpiry(now)}`,
  );
});

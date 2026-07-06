// 순수 로직 단위 테스트 — PI-3 좌표 거부 가드, PIN 해시, P0-1 시간창 판정.
import { assert, assertEquals } from "jsr:@std/assert@1";
import { findCoordinateKey, pinHash, sessionTimeVerdict } from "./checkin.ts";

Deno.test("findCoordinateKey: 최상위 좌표 키 탐지", () => {
  assertEquals(findCoordinateKey({ session_id: "s", lat: 37.5 }), "lat");
  assertEquals(findCoordinateKey({ Longitude: 127.0 }), "Longitude");
});

Deno.test("findCoordinateKey: 중첩 좌표 키 탐지", () => {
  assertEquals(findCoordinateKey({ meta: { device: { gps: { x: 1 } } } }), "gps");
  assertEquals(findCoordinateKey({ payload: { location: "37.5,127.0" } }), "location");
});

Deno.test("findCoordinateKey: 정상 payload는 통과", () => {
  assertEquals(findCoordinateKey({ session_id: "s", major: 101, minor: 4242 }), null);
  assertEquals(findCoordinateKey({ session_id: "s", code: "123456" }), null);
});

Deno.test("pinHash: 결정적 sha256 hex, 학생별 상이", async () => {
  const a = await pinHash("student-a", "1234");
  const b = await pinHash("student-a", "1234");
  const c = await pinHash("student-b", "1234");
  assertEquals(a, b);
  assert(a !== c, "같은 PIN이라도 학생이 다르면 해시가 달라야 함");
  assert(/^[0-9a-f]{64}$/.test(a));
});

// ── P0-1 시간창 판정 (RESEARCH_TIME_WINDOW §5.2) ──
const START = "2026-07-06T09:00:00.000Z";
const at = (minutes: number) =>
  new Date(Date.parse(START) + minutes * 60_000);

Deno.test("sessionTimeVerdict: close_at null = 무기한 present (하위 호환)", () => {
  const s = { started_at: START, close_at: null, auto_late_after_minutes: null };
  assertEquals(sessionTimeVerdict(s, at(0)), "present");
  assertEquals(sessionTimeVerdict(s, at(9999)), "present");
});

Deno.test("sessionTimeVerdict: 창 내 present, close_at 이후 closed (경계 포함)", () => {
  const s = {
    started_at: START,
    close_at: at(10).toISOString(),
    auto_late_after_minutes: null,
  };
  assertEquals(sessionTimeVerdict(s, at(9)), "present");
  assertEquals(sessionTimeVerdict(s, at(10)), "closed", "close_at 정각 = 마감");
  assertEquals(sessionTimeVerdict(s, at(11)), "closed");
});

Deno.test("sessionTimeVerdict: 지각 구간 [late_after, close_at) = late", () => {
  const s = {
    started_at: START,
    close_at: at(30).toISOString(),
    auto_late_after_minutes: 10,
  };
  assertEquals(sessionTimeVerdict(s, at(9)), "present");
  assertEquals(sessionTimeVerdict(s, at(10)), "late", "late_after 정각 = 지각");
  assertEquals(sessionTimeVerdict(s, at(29)), "late");
  assertEquals(sessionTimeVerdict(s, at(30)), "closed");
});

Deno.test("sessionTimeVerdict: auto_late만 있고 close_at 없으면 늦어도 계속 late 수집", () => {
  const s = { started_at: START, close_at: null, auto_late_after_minutes: 10 };
  assertEquals(sessionTimeVerdict(s, at(5)), "present");
  assertEquals(sessionTimeVerdict(s, at(500)), "late");
});

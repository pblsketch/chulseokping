// 순수 로직 단위 테스트 — PI-3 좌표 거부 가드, PIN 해시.
import { assert, assertEquals } from "jsr:@std/assert@1";
import { findCoordinateKey, pinHash } from "./checkin.ts";

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

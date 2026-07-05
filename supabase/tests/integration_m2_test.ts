// M2 백엔드 통합 테스트 — kiosk_sync (기기 토큰 인증 + 학급/secret/활성 세션 반환).
// 전제: supabase start + db reset (seed 적용) 직후 실행.
//   deno test --allow-env --allow-net supabase/tests/integration_m2_test.ts
import { assert, assertEquals } from "jsr:@std/assert@1";
import { createClient } from "npm:@supabase/supabase-js@2";

const URL = Deno.env.get("SUPABASE_URL") ?? "http://127.0.0.1:54321";
const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const CLASS_ID = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";
const SESSION_ID = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb";
const DEVICE_ID = "cccccccc-cccc-cccc-cccc-cccccccccccc";
const DEVICE_TOKEN = "dummy-kiosk-token-001";

const svc = createClient(URL, SERVICE, { auth: { persistSession: false } });

function itest(name: string, fn: () => Promise<void>) {
  Deno.test({ name, fn, sanitizeOps: false, sanitizeResources: false });
}

async function callSync(body: unknown) {
  const res = await fetch(`${URL}/functions/v1/kiosk_sync`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${ANON}`,
      apikey: ANON,
    },
    body: JSON.stringify(body),
  });
  return { status: res.status, body: await res.json() };
}

itest("kiosk_sync: 유효 토큰 → 학급·secret·활성 세션 반환 + last_seen 갱신", async () => {
  const before = await svc
    .from("kiosk_devices")
    .select("last_seen_at")
    .eq("id", DEVICE_ID)
    .single();

  const res = await callSync({ device_token: DEVICE_TOKEN });
  assertEquals(res.status, 200, JSON.stringify(res.body));
  assertEquals(res.body.class_id, CLASS_ID);
  assertEquals(res.body.class_name, "더미 1학년 1반");
  assertEquals(res.body.beacon_major, 101);
  assert(typeof res.body.beacon_secret === "string" && res.body.beacon_secret.length > 0);
  assert(typeof res.body.qr_secret === "string" && res.body.qr_secret.length > 0);
  assertEquals(res.body.session?.id, SESSION_ID, "seed의 활성 세션이 잡혀야 함");

  const after = await svc
    .from("kiosk_devices")
    .select("last_seen_at")
    .eq("id", DEVICE_ID)
    .single();
  assert(
    after.data!.last_seen_at !== before.data!.last_seen_at,
    "last_seen_at이 갱신되어야 함",
  );
});

itest("kiosk_sync: 알 수 없는 토큰 → 401", async () => {
  const res = await callSync({ device_token: "no-such-token" });
  assertEquals(res.status, 401, JSON.stringify(res.body));
  assertEquals(res.body.error, "unknown_device");
});

itest("kiosk_sync: revoke된 기기 → 401, 복구 후 다시 200", async () => {
  await svc.from("kiosk_devices").update({ revoked: true }).eq("id", DEVICE_ID);
  const revoked = await callSync({ device_token: DEVICE_TOKEN });
  assertEquals(revoked.status, 401, JSON.stringify(revoked.body));

  await svc.from("kiosk_devices").update({ revoked: false }).eq("id", DEVICE_ID);
  const restored = await callSync({ device_token: DEVICE_TOKEN });
  assertEquals(restored.status, 200);
});

itest("kiosk_sync: 세션 종료 후에는 session=null", async () => {
  await svc.from("sessions").update({ status: "ENDED" }).eq("id", SESSION_ID);
  const res = await callSync({ device_token: DEVICE_TOKEN });
  assertEquals(res.status, 200);
  assertEquals(res.body.session, null, "종료된 세션은 반환하지 않아야 함 (BE-5)");
  // 원복 (다른 테스트 순서 영향 방지)
  await svc.from("sessions").update({ status: "ACTIVE" }).eq("id", SESSION_ID);
});

itest("kiosk_sync: 좌표 포함 payload → 400 (PI-3 공통 가드)", async () => {
  const res = await callSync({ device_token: DEVICE_TOKEN, lat: 37.5 });
  assertEquals(res.status, 400);
  assertEquals(res.body.error, "coordinates_forbidden");
});

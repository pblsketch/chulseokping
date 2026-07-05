// M0 Exit 게이트 통합 테스트 (PRD M0 Exit + US-006)
// 전제: `supabase start` + `supabase db reset` (seed 적용) 완료 상태.
// 실행:
//   deno test --allow-env --allow-net supabase/tests/integration_m0_test.ts
// 환경변수: SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY (supabase status 값)
import { assert, assertEquals } from "jsr:@std/assert@1";
import { createClient } from "npm:@supabase/supabase-js@2";
import { beaconMinor, totpCode } from "../functions/_shared/totp.ts";
import { pinHash } from "../functions/_shared/checkin.ts";

const URL = Deno.env.get("SUPABASE_URL") ?? "http://127.0.0.1:54321";
const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// seed.sql의 고정 UUID
const CLASS_ID = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";
const SESSION_ID = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb";
const DEVICE_TOKEN = "dummy-kiosk-token-001";
const BEACON_MAJOR = 101;
const STUDENT1 = "22222222-2222-2222-2222-222222222222"; // 동의O, 멤버
const STUDENT4 = "55555555-5555-5555-5555-555555555555"; // 동의O, 멤버 (BLE용)
const STUDENT5 = "66666666-6666-6666-6666-666666666666"; // 동의O, 멤버 (PIN용)

const svc = createClient(URL, SERVICE, { auth: { persistSession: false } });

// supabase-js가 내부 타이머를 유지하므로 Deno 테스트의 리소스 sanitizer는 끈다.
function itest(name: string, fn: () => Promise<void>) {
  Deno.test({ name, fn, sanitizeOps: false, sanitizeResources: false });
}

async function signIn(email: string) {
  const client = createClient(URL, ANON, { auth: { persistSession: false } });
  const { data, error } = await client.auth.signInWithPassword({
    email,
    password: "password123",
  });
  if (error) throw new Error(`sign-in failed for ${email}: ${error.message}`);
  return { client, token: data.session!.access_token };
}

async function callFn(name: string, body: unknown, jwt?: string) {
  const res = await fetch(`${URL}/functions/v1/${name}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${jwt ?? ANON}`,
      apikey: ANON,
    },
    body: JSON.stringify(body),
  });
  return { status: res.status, body: await res.json() };
}

async function rowCount(studentId: string): Promise<number> {
  const { count } = await svc
    .from("attendance_logs")
    .select("id", { count: "exact", head: true })
    .eq("student_id", studentId)
    .eq("session_id", SESSION_ID);
  return count ?? 0;
}

itest("RLS: anon 클라이언트의 attendance_logs 직접 INSERT 거부", async () => {
  const anon = createClient(URL, ANON, { auth: { persistSession: false } });
  const { error } = await anon.from("attendance_logs").insert({
    student_id: STUDENT1,
    class_id: CLASS_ID,
    session_id: SESSION_ID,
    method: "QR",
    status: "present",
  });
  assert(error !== null, "anon 직접 INSERT는 반드시 거부되어야 함 (BE-0)");
});

itest("RLS: 로그인한 학생의 attendance_logs 직접 INSERT 거부", async () => {
  const { client } = await signIn("dummy-student1@example.com");
  const { error } = await client.from("attendance_logs").insert({
    student_id: STUDENT1,
    class_id: CLASS_ID,
    session_id: SESSION_ID,
    method: "QR",
    status: "present",
  });
  assert(error !== null, "authenticated 직접 INSERT는 반드시 거부되어야 함 (BE-0)");
});

itest("check_in_qr: 유효 TOTP → 1행, 재호출 → 멱등(여전히 1행)", async () => {
  const { token } = await signIn("dummy-student1@example.com");
  const { data: secret } = await svc
    .from("class_secrets")
    .select("qr_secret")
    .eq("class_id", CLASS_ID)
    .single();
  const code = await totpCode(secret!.qr_secret, {});

  const first = await callFn("check_in_qr", { session_id: SESSION_ID, code }, token);
  assertEquals(first.status, 200, JSON.stringify(first.body));
  assertEquals(first.body.created, true);
  assertEquals(await rowCount(STUDENT1), 1);

  const code2 = await totpCode(secret!.qr_secret, {});
  const second = await callFn("check_in_qr", { session_id: SESSION_ID, code: code2 }, token);
  assertEquals(second.status, 200, JSON.stringify(second.body));
  assertEquals(second.body.created, false, "재호출은 created:false (멱등)");
  assertEquals(await rowCount(STUDENT1), 1, "행 수는 여전히 1 (BE-2)");
});

itest("check_in_qr: 만료된 TOTP → 422", async () => {
  const { token } = await signIn("dummy-student1@example.com");
  const { data: secret } = await svc
    .from("class_secrets")
    .select("qr_secret")
    .eq("class_id", CLASS_ID)
    .single();
  const stale = await totpCode(secret!.qr_secret, { timestampMs: Date.now() - 60_000 });
  const res = await callFn("check_in_qr", { session_id: SESSION_ID, code: stale }, token);
  assertEquals(res.status, 422, JSON.stringify(res.body));
});

itest("동의 가드: 동의 없는 학생(student2) → 403 (PI-2 서버 강제)", async () => {
  const { token } = await signIn("dummy-student2@example.com");
  const { data: secret } = await svc
    .from("class_secrets")
    .select("qr_secret")
    .eq("class_id", CLASS_ID)
    .single();
  const code = await totpCode(secret!.qr_secret, {});
  const res = await callFn("check_in_qr", { session_id: SESSION_ID, code }, token);
  assertEquals(res.status, 403, JSON.stringify(res.body));
  assertEquals(res.body.error, "consent_required");
});

itest("멤버십 가드: 비멤버 학생(student3) → 403 (BE-2)", async () => {
  const { token } = await signIn("dummy-student3@example.com");
  const { data: secret } = await svc
    .from("class_secrets")
    .select("qr_secret")
    .eq("class_id", CLASS_ID)
    .single();
  const code = await totpCode(secret!.qr_secret, {});
  const res = await callFn("check_in_qr", { session_id: SESSION_ID, code }, token);
  assertEquals(res.status, 403, JSON.stringify(res.body));
  assertEquals(res.body.error, "not_a_member");
});

itest("PI-3: 좌표 포함 payload → 400 즉시 거부", async () => {
  const { token } = await signIn("dummy-student1@example.com");
  const res = await callFn(
    "check_in_qr",
    { session_id: SESSION_ID, code: "000000", lat: 37.5, lng: 127.0 },
    token,
  );
  assertEquals(res.status, 400, JSON.stringify(res.body));
  assertEquals(res.body.error, "coordinates_forbidden");
});

itest("check_in_ble: 회전 minor 유효 → 출석, 잘못된 minor → 422", async () => {
  const { token } = await signIn("dummy-student4@example.com");
  const { data: device } = await svc
    .from("kiosk_devices")
    .select("beacon_secret")
    .eq("device_token", DEVICE_TOKEN)
    .single();

  const minor = await beaconMinor(device!.beacon_secret, {});
  const ok = await callFn(
    "check_in_ble",
    { session_id: SESSION_ID, major: BEACON_MAJOR, minor },
    token,
  );
  assertEquals(ok.status, 200, JSON.stringify(ok.body));
  assertEquals(ok.body.created, true);
  assertEquals(await rowCount(STUDENT4), 1);

  const bad = await callFn(
    "check_in_ble",
    { session_id: SESSION_ID, major: BEACON_MAJOR, minor: (minor + 7) % 65536 },
    token,
  );
  assertEquals(bad.status, 422, JSON.stringify(bad.body));
});

itest("check_in_pin: 기기 토큰 + 명단 + PIN → 출석 (JWT 불필요)", async () => {
  // M0: PIN 해시를 테스트가 심는다 (seed에는 평문 PIN을 두지 않음)
  const hash = await pinHash(STUDENT5, "4321");
  await svc.from("profiles").update({ pin_hash: hash }).eq("id", STUDENT5);

  const ok = await callFn("check_in_pin", {
    device_token: DEVICE_TOKEN,
    session_id: SESSION_ID,
    student_number: "10105",
    pin: "4321",
  });
  assertEquals(ok.status, 200, JSON.stringify(ok.body));
  assertEquals(ok.body.created, true);
  assertEquals(await rowCount(STUDENT5), 1);

  const wrongPin = await callFn("check_in_pin", {
    device_token: DEVICE_TOKEN,
    session_id: SESSION_ID,
    student_number: "10105",
    pin: "0000",
  });
  assertEquals(wrongPin.status, 401, JSON.stringify(wrongPin.body));

  const wrongDevice = await callFn("check_in_pin", {
    device_token: "no-such-device",
    session_id: SESSION_ID,
    student_number: "10105",
    pin: "4321",
  });
  assertEquals(wrongDevice.status, 401, JSON.stringify(wrongDevice.body));
});

itest("교차 방법 중복: QR 출석자(student1)의 BLE 재시도 → 멱등 + suspicious_flag", async () => {
  const { token } = await signIn("dummy-student1@example.com");
  const { data: device } = await svc
    .from("kiosk_devices")
    .select("beacon_secret")
    .eq("device_token", DEVICE_TOKEN)
    .single();
  const minor = await beaconMinor(device!.beacon_secret, {});
  const res = await callFn(
    "check_in_ble",
    { session_id: SESSION_ID, major: BEACON_MAJOR, minor },
    token,
  );
  assertEquals(res.status, 200, JSON.stringify(res.body));
  assertEquals(res.body.created, false, "최초 method(QR) 유지, 새 행 없음");
  assertEquals(await rowCount(STUDENT1), 1);

  const { count } = await svc
    .from("suspicious_flags")
    .select("id", { count: "exact", head: true })
    .eq("student_id", STUDENT1)
    .eq("flag_type", "duplicate_method");
  assert((count ?? 0) >= 1, "duplicate_method 플래그가 기록되어야 함 (로그-온리)");
});

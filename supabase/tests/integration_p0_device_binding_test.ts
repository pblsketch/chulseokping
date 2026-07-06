// P0-2 기기 바인딩 통합 테스트 — 자동 등록/재바인딩 승인/로그-온리 플래그.
// 핵심 계약: 어떤 기기 상태에서도 출석 기록은 차단되지 않는다 (suspicious_flags만).
// 전제: supabase start + db reset (seed 적용) 직후 실행.
import { assert, assertEquals } from "jsr:@std/assert@1";
import { createClient } from "npm:@supabase/supabase-js@2";
import { totpCode } from "../functions/_shared/totp.ts";

const URL = Deno.env.get("SUPABASE_URL") ?? "http://127.0.0.1:54321";
const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const CLASS_ID = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";
const TEACHER_ID = "11111111-1111-1111-1111-111111111111";
const STUDENT1 = "22222222-2222-2222-2222-222222222222";
const STUDENT4 = "55555555-5555-5555-5555-555555555555";
const STUDENT5 = "66666666-6666-6666-6666-666666666666";

const svc = createClient(URL, SERVICE, { auth: { persistSession: false } });

function itest(name: string, fn: () => Promise<void>) {
  Deno.test({ name, fn, sanitizeOps: false, sanitizeResources: false });
}

async function signIn(email: string) {
  const client = createClient(URL, ANON, { auth: { persistSession: false } });
  const { data, error } = await client.auth.signInWithPassword({
    email,
    password: "password123",
  });
  if (error) throw new Error(`sign-in failed: ${error.message}`);
  return data.session!.access_token;
}

async function callFn(name: string, body: unknown, jwt: string) {
  const res = await fetch(`${URL}/functions/v1/${name}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${jwt}`,
      apikey: ANON,
    },
    body: JSON.stringify(body),
  });
  return { status: res.status, body: await res.json() };
}

async function makeQrSession(period: number): Promise<string> {
  const { data, error } = await svc
    .from("sessions")
    .insert({
      class_id: CLASS_ID,
      teacher_id: TEACHER_ID,
      type: "PERIOD",
      period,
      mode: "BYOD",
      status: "ACTIVE",
    })
    .select("id")
    .single();
  if (error) throw new Error(error.message);
  return data.id as string;
}

async function qrBody(sessionId: string, deviceUuid?: string) {
  const { data: secret } = await svc
    .from("class_secrets")
    .select("qr_secret")
    .eq("class_id", CLASS_ID)
    .single();
  return {
    session_id: sessionId,
    code: await totpCode(secret!.qr_secret, {}),
    device_uuid: deviceUuid,
  };
}

async function flagCount(studentId: string, flagType: string) {
  const { count } = await svc
    .from("suspicious_flags")
    .select("id", { count: "exact", head: true })
    .eq("student_id", studentId)
    .eq("flag_type", flagType);
  return count ?? 0;
}

itest("register_device: 최초 자동 active + 같은 uuid 재등록 멱등", async () => {
  const jwt = await signIn("dummy-student1@example.com");
  const first = await callFn("register_device", { platform: "android" }, jwt);
  assertEquals(first.status, 200, JSON.stringify(first.body));
  assertEquals(first.body.status, "active", "최초 등록은 무마찰 자동 active");
  const uuid = first.body.device_uuid as string;

  const again = await callFn(
    "register_device",
    { platform: "android", device_uuid: uuid },
    jwt,
  );
  assertEquals(again.body.device_uuid, uuid, "같은 기기 재로그인은 멱등");
  assertEquals(again.body.status, "active");

  const { count } = await svc
    .from("student_devices")
    .select("id", { count: "exact", head: true })
    .eq("student_id", STUDENT1);
  assertEquals(count, 1, "행이 늘어나면 안 됨");
});

itest("재바인딩: pending → 교사 승인 → 교체(active/revoked), 학생 승인은 403", async () => {
  const studentJwt = await signIn("dummy-student1@example.com");
  const second = await callFn("register_device", { platform: "ios" }, studentJwt);
  assertEquals(second.body.status, "pending", "active 존재 시 새 기기는 승인 대기");

  const { data: pendingRow } = await svc
    .from("student_devices")
    .select("id")
    .eq("student_id", STUDENT1)
    .eq("status", "pending")
    .single();

  // 학생 스스로 승인 불가
  const selfApprove = await callFn(
    "approve_device",
    { device_id: pendingRow!.id, action: "approve" },
    studentJwt,
  );
  assertEquals(selfApprove.status, 403);

  const teacherJwt = await signIn("dummy-teacher@example.com");
  const approve = await callFn(
    "approve_device",
    { device_id: pendingRow!.id, action: "approve" },
    teacherJwt,
  );
  assertEquals(approve.status, 200, JSON.stringify(approve.body));

  const { data: devices } = await svc
    .from("student_devices")
    .select("id, status, replaced_by")
    .eq("student_id", STUDENT1)
    .order("registered_at");
  assertEquals(devices!.length, 2);
  assertEquals(devices![0].status, "revoked", "기존 기기는 회수");
  assertEquals(devices![0].replaced_by, pendingRow!.id, "교체 흔적");
  assertEquals(devices![1].status, "active", "새 기기 활성");
});

itest("30일 내 재바인딩 반복 → RAPID_DEVICE_REBIND 로그-온리", async () => {
  const jwt = await signIn("dummy-student1@example.com");
  const third = await callFn("register_device", { platform: "android" }, jwt);
  assertEquals(third.body.status, "pending");
  assert(
    (await flagCount(STUDENT1, "RAPID_DEVICE_REBIND")) >= 1,
    "잦은 재바인딩 신호 기록",
  );
});

itest("체크인: 본인 active 기기 → student_device_id 기록, 플래그 없음", async () => {
  const sessionId = await makeQrSession(11);
  const jwt = await signIn("dummy-student1@example.com");
  const { data: active } = await svc
    .from("student_devices")
    .select("id, device_uuid")
    .eq("student_id", STUDENT1)
    .eq("status", "active")
    .single();

  const res = await callFn(
    "check_in_qr",
    await qrBody(sessionId, active!.device_uuid),
    jwt,
  );
  assertEquals(res.status, 200, JSON.stringify(res.body));
  assertEquals(res.body.record.student_device_id, active!.id);
  assertEquals(await flagCount(STUDENT1, "UNBOUND_DEVICE_CHECKIN"), 0);
});

itest("체크인: 타인 기기 uuid → 출석은 기록(차단 없음) + MULTI_ACCOUNT 플래그", async () => {
  const sessionId = await makeQrSession(12);
  const { data: owner } = await svc
    .from("student_devices")
    .select("device_uuid")
    .eq("student_id", STUDENT1)
    .eq("status", "active")
    .single();

  const jwt = await signIn("dummy-student4@example.com");
  const res = await callFn(
    "check_in_qr",
    await qrBody(sessionId, owner!.device_uuid),
    jwt,
  );
  assertEquals(res.status, 200, "로그-온리 — 출석 자체는 기록");
  assertEquals(res.body.record.student_device_id, null);
  assertEquals(await flagCount(STUDENT4, "MULTI_ACCOUNT_SAME_DEVICE"), 1);
});

itest("체크인: 미등록 uuid → 기록 + UNBOUND 플래그 / uuid 없으면(구버전) 무플래그", async () => {
  const sessionId = await makeQrSession(13);
  const jwt = await signIn("dummy-student5@example.com");
  const res = await callFn(
    "check_in_qr",
    await qrBody(sessionId, crypto.randomUUID()),
    jwt,
  );
  assertEquals(res.status, 200);
  assertEquals(await flagCount(STUDENT5, "UNBOUND_DEVICE_CHECKIN"), 1);

  // 구버전 클라(uuid 미전송): student4가 다른 세션에 무플래그로 체크인
  const sessionId2 = await makeQrSession(14);
  const jwt4 = await signIn("dummy-student4@example.com");
  const bare = await callFn("check_in_qr", await qrBody(sessionId2), jwt4);
  assertEquals(bare.status, 200);
  assertEquals(await flagCount(STUDENT4, "UNBOUND_DEVICE_CHECKIN"), 0);
});

itest("SHARED_DEVICE: 동일 App Set ID 타 학생 → 차단 없이 신호만", async () => {
  const jwt4 = await signIn("dummy-student4@example.com");
  const first = await callFn(
    "register_device",
    { platform: "android", app_set_id: "shared-family-tablet" },
    jwt4,
  );
  assertEquals(first.status, 200);
  assertEquals(await flagCount(STUDENT4, "SHARED_DEVICE"), 0, "첫 등록은 중복 없음");

  const jwt5 = await signIn("dummy-student5@example.com");
  const second = await callFn(
    "register_device",
    { platform: "android", app_set_id: "shared-family-tablet" },
    jwt5,
  );
  assertEquals(second.status, 200);
  assertEquals(second.body.status, "active", "형제 공유 기기도 차단하지 않는다");
  assertEquals(await flagCount(STUDENT5, "SHARED_DEVICE"), 1);
});

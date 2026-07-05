// M4 백엔드 통합 테스트 — set_student_pin (교사 PIN 발급 → 키오스크 PIN 체크인 왕복).
// 전제: supabase start + db reset (seed 적용) 직후 실행.
import { assertEquals } from "jsr:@std/assert@1";
import { createClient } from "npm:@supabase/supabase-js@2";

const URL = Deno.env.get("SUPABASE_URL") ?? "http://127.0.0.1:54321";
const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const SESSION_ID = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb";
const DEVICE_TOKEN = "dummy-kiosk-token-001";
const STUDENT6 = "77777777-7777-7777-7777-777777777777"; // 동의O, 멤버 — M1과 다른 세션 단계라 재사용 무방
const STUDENT3 = "44444444-4444-4444-4444-444444444444"; // 동의O, 비멤버(담당 아님)

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

itest("set_student_pin: 교사 발급 → 해시 저장(평문 아님) → PIN 체크인 성공 왕복", async () => {
  const teacher = await signIn("dummy-teacher@example.com");
  const set = await callFn(
    "set_student_pin",
    { student_id: STUDENT6, pin: "9876" },
    teacher,
  );
  assertEquals(set.status, 200, JSON.stringify(set.body));

  const { data: profile } = await svc
    .from("profiles")
    .select("pin_hash")
    .eq("id", STUDENT6)
    .single();
  assertEquals(profile!.pin_hash.length, 64, "sha256 hex 해시여야 함");
  assertEquals(profile!.pin_hash.includes("9876"), false, "평문 저장 금지");

  const checkIn = await callFn("check_in_pin", {
    device_token: DEVICE_TOKEN,
    session_id: SESSION_ID,
    student_number: "10106",
    pin: "9876",
  });
  assertEquals(checkIn.status, 200, JSON.stringify(checkIn.body));

  const wrong = await callFn("check_in_pin", {
    device_token: DEVICE_TOKEN,
    session_id: SESSION_ID,
    student_number: "10106",
    pin: "0000",
  });
  assertEquals(wrong.status, 401, "틀린 PIN은 거부");
});

itest("set_student_pin: 형식 검증 — 숫자 4~8자리 외 400", async () => {
  const teacher = await signIn("dummy-teacher@example.com");
  for (const pin of ["12", "123456789", "12ab"]) {
    const res = await callFn(
      "set_student_pin",
      { student_id: STUDENT6, pin },
      teacher,
    );
    assertEquals(res.status, 400, `pin=${pin}`);
  }
});

itest("set_student_pin: 담당 아닌 학생(비멤버) → 403", async () => {
  const teacher = await signIn("dummy-teacher@example.com");
  const res = await callFn(
    "set_student_pin",
    { student_id: STUDENT3, pin: "1234" },
    teacher,
  );
  assertEquals(res.status, 403, JSON.stringify(res.body));
});

itest("set_student_pin: 학생 토큰 → 403 (자기 PIN도 교사 경유)", async () => {
  const student = await signIn("dummy-student1@example.com");
  const res = await callFn(
    "set_student_pin",
    { student_id: STUDENT6, pin: "1234" },
    student,
  );
  assertEquals(res.status, 403, JSON.stringify(res.body));
});

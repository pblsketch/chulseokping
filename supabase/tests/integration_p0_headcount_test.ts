// P0-3 헤드카운트 통합 테스트 — 서버 집계·확인 기록·불일치 플래그(로그-온리).
// 전제: supabase start + db reset (seed 적용) 직후 실행.
import { assert, assertEquals } from "jsr:@std/assert@1";
import { createClient } from "npm:@supabase/supabase-js@2";

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

/** QR 1건 + BLE 1건 + MANUAL 1건이 든 세션 — 자동 집계 대상은 2여야 한다 */
async function makeSessionWithLogs(): Promise<string> {
  const { data: session, error } = await svc
    .from("sessions")
    .insert({
      class_id: CLASS_ID,
      teacher_id: TEACHER_ID,
      type: "PERIOD",
      period: 15,
      mode: "BYOD",
      status: "ACTIVE",
    })
    .select("id")
    .single();
  if (error) throw new Error(error.message);

  const { error: logError } = await svc.from("attendance_logs").insert([
    {
      student_id: STUDENT1,
      class_id: CLASS_ID,
      session_id: session.id,
      method: "QR",
      status: "present",
    },
    {
      student_id: STUDENT4,
      class_id: CLASS_ID,
      session_id: session.id,
      method: "BLE",
      status: "present",
    },
    {
      student_id: STUDENT5,
      class_id: CLASS_ID,
      session_id: session.id,
      method: "MANUAL",
      status: "present",
    },
  ]);
  if (logError) throw new Error(logError.message);
  return session.id as string;
}

itest("맞아요: 확인 시각 기록 + auto_count는 QR/BLE만(2) + 플래그 없음", async () => {
  const sessionId = await makeSessionWithLogs();
  const teacher = await signIn("dummy-teacher@example.com");

  const res = await callFn(
    "confirm_headcount",
    { session_id: sessionId, matches: true },
    teacher,
  );
  assertEquals(res.status, 200, JSON.stringify(res.body));
  assertEquals(res.body.auto_count, 2, "MANUAL은 자동 집계에서 제외");

  const { data: session } = await svc
    .from("sessions")
    .select("headcount_confirmed_at")
    .eq("id", sessionId)
    .single();
  assert(session!.headcount_confirmed_at !== null);

  const { count } = await svc
    .from("suspicious_flags")
    .select("id", { count: "exact", head: true })
    .eq("session_id", sessionId)
    .eq("flag_type", "CHECKIN_HEADCOUNT_GAP");
  assertEquals(count, 0);
});

itest("아니요: CHECKIN_HEADCOUNT_GAP 플래그(서버 집계 + 관측 인원)", async () => {
  const sessionId = await makeSessionWithLogs();
  const teacher = await signIn("dummy-teacher@example.com");

  const res = await callFn(
    "confirm_headcount",
    { session_id: sessionId, matches: false, observed_count: 1 },
    teacher,
  );
  assertEquals(res.status, 200, JSON.stringify(res.body));

  const { data: flags } = await svc
    .from("suspicious_flags")
    .select("evidence")
    .eq("session_id", sessionId)
    .eq("flag_type", "CHECKIN_HEADCOUNT_GAP");
  assertEquals(flags!.length, 1);
  assertEquals(flags![0].evidence.auto_count, 2, "집계는 서버가 한다");
  assertEquals(flags![0].evidence.observed_count, 1);
});

itest("담당 아닌 사용자(학생 토큰) → 403", async () => {
  const sessionId = await makeSessionWithLogs();
  const student = await signIn("dummy-student1@example.com");
  const res = await callFn(
    "confirm_headcount",
    { session_id: sessionId, matches: true },
    student,
  );
  assertEquals(res.status, 403);
});

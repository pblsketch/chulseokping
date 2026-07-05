// M1 백엔드 통합 테스트 — update_attendance(교사 수동 수정) + class_secrets 교사 읽기.
// 전제: supabase start + db reset (seed 적용) 직후 실행.
//   deno test --allow-env --allow-net supabase/tests/integration_m1_test.ts
import { assert, assertEquals } from "jsr:@std/assert@1";
import { createClient } from "npm:@supabase/supabase-js@2";
import { totpCode } from "../functions/_shared/totp.ts";

const URL = Deno.env.get("SUPABASE_URL") ?? "http://127.0.0.1:54321";
const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const CLASS_ID = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";
const SESSION_ID = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb";
const STUDENT1 = "22222222-2222-2222-2222-222222222222"; // 동의O, 멤버
const STUDENT2 = "33333333-3333-3333-3333-333333333333"; // 동의X, 멤버
const STUDENT6 = "77777777-7777-7777-7777-777777777777"; // 동의O, 멤버 — M1 수동 전용(다른 스위트가 건드리지 않음)

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

itest("class_secrets: 교사는 자기 학급 secret 읽기 가능, 학생은 0행", async () => {
  const teacher = await signIn("dummy-teacher@example.com");
  const { data: teacherRows, error } = await teacher.client
    .from("class_secrets")
    .select("qr_secret")
    .eq("class_id", CLASS_ID);
  assertEquals(error, null);
  assertEquals(teacherRows?.length, 1, "교사는 secret 1행을 읽어야 함 (회전 QR 표시용)");

  const student = await signIn("dummy-student1@example.com");
  const { data: studentRows } = await student.client
    .from("class_secrets")
    .select("qr_secret")
    .eq("class_id", CLASS_ID);
  assertEquals(studentRows?.length ?? 0, 0, "학생은 secret에 접근 불가");
});

itest("update_attendance: 체크인된 행을 지각/질병으로 수정", async () => {
  // 선행: student1 QR 체크인으로 행 생성
  const student = await signIn("dummy-student1@example.com");
  const { data: secret } = await svc
    .from("class_secrets")
    .select("qr_secret")
    .eq("class_id", CLASS_ID)
    .single();
  const code = await totpCode(secret!.qr_secret, {});
  const checkIn = await callFn(
    "check_in_qr",
    { session_id: SESSION_ID, code },
    student.token,
  );
  assertEquals(checkIn.status, 200, JSON.stringify(checkIn.body));
  const recordId = checkIn.body.record.id as string;

  const teacher = await signIn("dummy-teacher@example.com");
  const res = await callFn(
    "update_attendance",
    { record_id: recordId, status: "late", reason: "sick", reason_detail: "병원 진료" },
    teacher.token,
  );
  assertEquals(res.status, 200, JSON.stringify(res.body));
  assertEquals(res.body.record.status, "late");
  assertEquals(res.body.record.reason, "sick");
  assertEquals(res.body.record.updated_by, "11111111-1111-1111-1111-111111111111");
});

itest("update_attendance: 미출석 학생 결석 처리(행 생성, method=MANUAL) + 재호출 멱등", async () => {
  const teacher = await signIn("dummy-teacher@example.com");
  const first = await callFn(
    "update_attendance",
    {
      session_id: SESSION_ID,
      student_id: STUDENT6,
      status: "absent",
      reason: "unrecognized",
    },
    teacher.token,
  );
  assertEquals(first.status, 200, JSON.stringify(first.body));
  assertEquals(first.body.created, true);
  assertEquals(first.body.record.method, "MANUAL");

  const second = await callFn(
    "update_attendance",
    { session_id: SESSION_ID, student_id: STUDENT6, status: "absent", reason: "other" },
    teacher.token,
  );
  assertEquals(second.status, 200, JSON.stringify(second.body));
  assertEquals(second.body.created, false, "재호출은 기존 행 갱신 (멱등)");
  assertEquals(second.body.record.reason, "other");

  const { count } = await svc
    .from("attendance_logs")
    .select("id", { count: "exact", head: true })
    .eq("student_id", STUDENT6)
    .eq("session_id", SESSION_ID);
  assertEquals(count, 1, "행은 여전히 1개");
});

itest("update_attendance: 교외체험학습이면 neis_excluded=true 서버 파생", async () => {
  const teacher = await signIn("dummy-teacher@example.com");
  const res = await callFn(
    "update_attendance",
    {
      session_id: SESSION_ID,
      student_id: STUDENT6,
      status: "absent",
      reason: "recognized",
      reason_code: "field_trip",
    },
    teacher.token,
  );
  assertEquals(res.status, 200, JSON.stringify(res.body));
  assertEquals(res.body.record.neis_excluded, true, "교외체험학습은 학생부 미기재 (§5)");
  assertEquals(res.body.record.reason, "recognized");
});

itest("update_attendance: 2축 검증 — 출석에 사유 400 / 비출석에 사유 누락 400 / 사유코드 오용 400", async () => {
  const teacher = await signIn("dummy-teacher@example.com");

  const presentWithReason = await callFn(
    "update_attendance",
    { session_id: SESSION_ID, student_id: STUDENT6, status: "present", reason: "sick" },
    teacher.token,
  );
  assertEquals(presentWithReason.status, 400);

  const absentNoReason = await callFn(
    "update_attendance",
    { session_id: SESSION_ID, student_id: STUDENT6, status: "absent" },
    teacher.token,
  );
  assertEquals(absentNoReason.status, 400);

  const codeWithoutRecognized = await callFn(
    "update_attendance",
    {
      session_id: SESSION_ID,
      student_id: STUDENT6,
      status: "absent",
      reason: "sick",
      reason_code: "field_trip",
    },
    teacher.token,
  );
  assertEquals(codeWithoutRecognized.status, 400);
});

itest("update_attendance: 학생 토큰은 403 (교사 아님)", async () => {
  const student = await signIn("dummy-student1@example.com");
  const res = await callFn(
    "update_attendance",
    { session_id: SESSION_ID, student_id: STUDENT1, status: "absent", reason: "other" },
    student.token,
  );
  assertEquals(res.status, 403, JSON.stringify(res.body));
});

itest("update_attendance: 동의 미확인 학생은 수동 입력도 403 (PI-2)", async () => {
  const teacher = await signIn("dummy-teacher@example.com");
  const res = await callFn(
    "update_attendance",
    { session_id: SESSION_ID, student_id: STUDENT2, status: "absent", reason: "other" },
    teacher.token,
  );
  assertEquals(res.status, 403, JSON.stringify(res.body));
  assertEquals(res.body.error, "consent_required");
});

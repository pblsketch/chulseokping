// M6 백엔드 통합 테스트 — create_class(secrets 동시 발급)·클라 INSERT 차단·보관·명단 제외.
// 전제: supabase start + db reset (seed 적용) 직후 실행.
import { assert, assertEquals, assertMatch } from "jsr:@std/assert@1";
import { createClient } from "npm:@supabase/supabase-js@2";

const URL = Deno.env.get("SUPABASE_URL") ?? "http://127.0.0.1:54321";
const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const svc = createClient(URL, SERVICE, { auth: { persistSession: false } });

function itest(name: string, fn: () => Promise<void>) {
  Deno.test({ name, fn, sanitizeOps: false, sanitizeResources: false });
}

async function signIn(email: string, password = "password123") {
  const client = createClient(URL, ANON, { auth: { persistSession: false } });
  const { data, error } = await client.auth.signInWithPassword({
    email,
    password,
  });
  if (error) throw new Error(`sign-in failed: ${error.message}`);
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

itest("create_class: 학급+QR secret 동시 발급, 교사 목록에 노출", async () => {
  const { client, token } = await signIn("dummy-teacher@example.com");
  const res = await callFn("create_class", { name: "M6 신규 1반" }, token);
  assertEquals(res.status, 200, JSON.stringify(res.body));
  const cls = res.body.class as Record<string, unknown>;
  assertEquals(cls.name, "M6 신규 1반");
  assertMatch(cls.invite_code as string, /^[A-HJ-NP-Z2-9]{8}$/);

  // ⚠ 함정 검증의 핵심: secret이 동시에 존재해야 QR이 동작한다
  const { data: secret } = await svc
    .from("class_secrets")
    .select("qr_secret")
    .eq("class_id", cls.id as string)
    .single();
  assertMatch(secret!.qr_secret, /^[0-9a-f]{40}$/, "20바이트 hex TOTP secret");

  // 교사 클라이언트(RLS)에서 새 학급이 보인다
  const { data: mine } = await client
    .from("classes")
    .select("id")
    .eq("id", cls.id as string);
  assertEquals(mine!.length, 1);
});

itest("create_class: 학생 토큰 → 403 / 이름 검증 400", async () => {
  const { token: student } = await signIn("dummy-student1@example.com");
  const forbidden = await callFn("create_class", { name: "학생학급" }, student);
  assertEquals(forbidden.status, 403);
  assertEquals(forbidden.body.error, "not_a_teacher");

  const { token: teacher } = await signIn("dummy-teacher@example.com");
  for (const name of ["", "  ", "가".repeat(31)]) {
    const bad = await callFn("create_class", { name }, teacher);
    assertEquals(bad.status, 400, `name="${name}"`);
  }
});

itest("classes 직접 INSERT는 교사 JWT로도 거부 (secret 없는 학급 방지)", async () => {
  const { client } = await signIn("dummy-teacher@example.com");
  const { error } = await client.from("classes").insert({
    teacher_id: "11111111-1111-1111-1111-111111111111",
    name: "직접삽입시도",
    invite_code: "DIRECTINS",
  });
  assert(error !== null, "클라 직접 INSERT는 반드시 거부 — create_class 경유 강제");
});

itest("이름 변경(클라 RLS) + 보관 → 활성 목록에서 제외, 이력은 보존", async () => {
  const { client, token } = await signIn("dummy-teacher@example.com");
  const created = await callFn("create_class", { name: "보관 대상 반" }, token);
  const classId = created.body.class.id as string;

  const { error: renameError } = await client
    .from("classes")
    .update({ name: "이름 바뀐 반" })
    .eq("id", classId);
  assertEquals(renameError, null);

  const { error: archiveError } = await client
    .from("classes")
    .update({ archived_at: new Date().toISOString() })
    .eq("id", classId);
  assertEquals(archiveError, null);

  // 앱 목록 쿼리와 동일 조건: archived_at is null → 제외
  const { data: active } = await client
    .from("classes")
    .select("id")
    .eq("id", classId)
    .is("archived_at", null);
  assertEquals(active!.length, 0, "보관 학급은 활성 목록에서 제외");

  // 행 자체는 보존 (이력 근거)
  const { data: row } = await svc
    .from("classes")
    .select("name, archived_at")
    .eq("id", classId)
    .single();
  assertEquals(row!.name, "이름 바뀐 반");
  assert(row!.archived_at !== null);
});

itest("명단 제외(전학/졸업): 멤버십만 해제 — 출결·계정 보존", async () => {
  const { client, token } = await signIn("dummy-teacher@example.com");
  // 자체 학급 + 학생 + 출결 이력 구성 (다른 스위트와 독립)
  const created = await callFn("create_class", { name: "전학 테스트 반" }, token);
  const classId = created.body.class.id as string;
  const made = await callFn(
    "create_students",
    {
      class_id: classId,
      students: [
        { name: "전학갈학생", student_number: "10301", guardian_consented: true },
      ],
    },
    token,
  );
  const studentId = made.body.students[0].student_id as string;

  const { data: session } = await svc
    .from("sessions")
    .insert({
      class_id: classId,
      teacher_id: "11111111-1111-1111-1111-111111111111",
      type: "HOMEROOM",
      mode: "BYOD",
      status: "ENDED",
    })
    .select("id")
    .single();
  await svc.from("attendance_logs").insert({
    student_id: studentId,
    class_id: classId,
    session_id: session!.id,
    method: "MANUAL",
    status: "present",
  });

  // 교사 클라이언트(RLS)로 명단 해제
  const { error: removeError } = await client
    .from("student_classes")
    .delete()
    .match({ class_id: classId, student_id: studentId });
  assertEquals(removeError, null);

  const { count: memberCount } = await svc
    .from("student_classes")
    .select("student_id", { count: "exact", head: true })
    .eq("student_id", studentId);
  assertEquals(memberCount, 0, "멤버십 해제됨");

  const { count: logCount } = await svc
    .from("attendance_logs")
    .select("id", { count: "exact", head: true })
    .eq("student_id", studentId);
  assertEquals(logCount, 1, "출결 이력은 보존 (나이스 근거)");

  const { count: profileCount } = await svc
    .from("profiles")
    .select("id", { count: "exact", head: true })
    .eq("id", studentId);
  assertEquals(profileCount, 1, "계정(프로필)도 보존");
  // 제외 후 체크인 거부는 멤버십 가드(M0 통합 테스트)가 보장한다.
});

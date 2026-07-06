// M5 백엔드 통합 테스트 — create_students / issue_link_code / redeem_link_code.
// 전제: supabase start + db reset (seed 적용) 직후 실행.
import { assertEquals, assertMatch } from "jsr:@std/assert@1";
import { createClient } from "npm:@supabase/supabase-js@2";

const URL = Deno.env.get("SUPABASE_URL") ?? "http://127.0.0.1:54321";
const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const CLASS_ID = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";
const LINK_CODE_DISPLAY = /^[A-HJ-NP-Z2-9]{4}-[A-HJ-NP-Z2-9]{4}-[A-HJ-NP-Z2-9]{4}$/;

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

itest("create_students: 일괄 생성 → 프로필/명단/동의/코드 해시 확인 → redeem 왕복", async () => {
  const teacher = await signIn("dummy-teacher@example.com");
  const res = await callFn(
    "create_students",
    {
      class_id: CLASS_ID,
      students: [
        { name: "신규일", student_number: "10201", guardian_consented: true },
        { name: "신규이", student_number: "10202" },
      ],
    },
    teacher,
  );
  assertEquals(res.status, 200, JSON.stringify(res.body));
  const rows = res.body.students as Record<string, unknown>[];
  assertEquals(rows.length, 2);
  for (const row of rows) {
    assertEquals(row.ok, true, JSON.stringify(row));
    assertMatch(row.link_code as string, LINK_CODE_DISPLAY);
  }
  const [consented, notConsented] = rows;

  // 프로필·명단·동의 반영
  const { data: profile } = await svc
    .from("profiles")
    .select("role, name, student_number, school_id")
    .eq("id", consented.student_id as string)
    .single();
  assertEquals(profile!.role, "student");
  assertEquals(profile!.student_number, "10201");

  const { count: memberCount } = await svc
    .from("student_classes")
    .select("student_id", { count: "exact", head: true })
    .eq("student_id", consented.student_id as string)
    .eq("class_id", CLASS_ID);
  assertEquals(memberCount, 1);

  const { count: consentCount } = await svc
    .from("consents")
    .select("id", { count: "exact", head: true })
    .eq("student_id", consented.student_id as string);
  assertEquals(consentCount, 1, "guardian_consented=true → consents 기록");

  const { count: noConsentCount } = await svc
    .from("consents")
    .select("id", { count: "exact", head: true })
    .eq("student_id", notConsented.student_id as string);
  assertEquals(noConsentCount, 0, "미동의 학생은 consents 없음");

  // 코드는 해시만 저장 (평문·표시형 모두 DB에 없어야 함)
  const { data: codeRow } = await svc
    .from("student_link_codes")
    .select("code_hash, used_at, expires_at")
    .eq("student_id", consented.student_id as string)
    .single();
  assertMatch(codeRow!.code_hash, /^[0-9a-f]{64}$/);
  assertEquals(codeRow!.used_at, null);

  // redeem → 1회용 자격 → 로그인 성공
  const redeem = await callFn("redeem_link_code", {
    code: consented.link_code as string,
  });
  assertEquals(redeem.status, 200, JSON.stringify(redeem.body));
  const studentJwt = await signIn(
    redeem.body.email as string,
    redeem.body.password as string,
  );
  assertEquals(typeof studentJwt, "string");

  // 같은 코드 재사용 → 404 (1회성 소비)
  const replay = await callFn("redeem_link_code", {
    code: consented.link_code as string,
  });
  assertEquals(replay.status, 404, "코드 재사용 거부");
});

itest("create_students: 학급 내 학번 중복은 행 단위 실패", async () => {
  const teacher = await signIn("dummy-teacher@example.com");
  const res = await callFn(
    "create_students",
    {
      class_id: CLASS_ID,
      students: [
        { name: "중복학번", student_number: "10101" }, // seed 학생1과 중복
        { name: "정상행", student_number: "10203" },
      ],
    },
    teacher,
  );
  assertEquals(res.status, 200);
  const rows = res.body.students as Record<string, unknown>[];
  assertEquals(rows[0].ok, false);
  assertEquals(rows[0].error, "duplicate_student_number");
  assertEquals(rows[1].ok, true, "다른 행은 정상 처리");
});

itest("create_students: 학생 토큰 → 403 (내 학급 아님)", async () => {
  const student = await signIn("dummy-student1@example.com");
  const res = await callFn(
    "create_students",
    {
      class_id: CLASS_ID,
      students: [{ name: "권한없음", student_number: "10299" }],
    },
    student,
  );
  assertEquals(res.status, 403, JSON.stringify(res.body));
});

itest("issue_link_code: 재발급이 기존 코드를 무효화한다", async () => {
  const teacher = await signIn("dummy-teacher@example.com");
  const created = await callFn(
    "create_students",
    {
      class_id: CLASS_ID,
      students: [{ name: "재발급대상", student_number: "10204" }],
    },
    teacher,
  );
  const first = created.body.students[0] as Record<string, unknown>;
  assertEquals(first.ok, true, JSON.stringify(first));

  const reissue = await callFn(
    "issue_link_code",
    { student_id: first.student_id },
    teacher,
  );
  assertEquals(reissue.status, 200, JSON.stringify(reissue.body));
  assertMatch(reissue.body.link_code as string, LINK_CODE_DISPLAY);

  // 최초 코드는 무효, 재발급 코드는 유효
  const oldRedeem = await callFn("redeem_link_code", {
    code: first.link_code as string,
  });
  assertEquals(oldRedeem.status, 404, "재발급 시 기존 코드 무효화");

  const newRedeem = await callFn("redeem_link_code", {
    code: reissue.body.link_code as string,
  });
  assertEquals(newRedeem.status, 200, JSON.stringify(newRedeem.body));
});

itest("issue_link_code: 담당 아닌 학생 → 403, 학생 토큰 → 403", async () => {
  const teacher = await signIn("dummy-teacher@example.com");
  const nonMember = await callFn(
    "issue_link_code",
    { student_id: "44444444-4444-4444-4444-444444444444" }, // seed 비멤버
    teacher,
  );
  assertEquals(nonMember.status, 403);

  const student = await signIn("dummy-student1@example.com");
  const res = await callFn(
    "issue_link_code",
    { student_id: "22222222-2222-2222-2222-222222222222" },
    student,
  );
  assertEquals(res.status, 403);
});

itest("redeem_link_code: 형식 오류 400 / 존재하지 않는 코드 404 / 좌표 거부 400", async () => {
  const badFormat = await callFn("redeem_link_code", { code: "SHORT" });
  assertEquals(badFormat.status, 400);

  const unknown = await callFn("redeem_link_code", {
    code: "AAAA-BBBB-CCCC",
  });
  assertEquals(unknown.status, 404);

  const coords = await callFn("redeem_link_code", {
    code: "AAAA-BBBB-CCCC",
    lat: 37.5,
  });
  assertEquals(coords.status, 400, "PI-3 좌표 거부");
  assertEquals(coords.body.error, "coordinates_forbidden");
});

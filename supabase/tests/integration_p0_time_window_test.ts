// P0-1 세션 수집 시간창 통합 테스트 — RESEARCH_TIME_WINDOW §5.4의 4케이스.
// ①창 내 present ②지각 구간 late ③close_at 이후 410 ④연장 후 재허용
// 전제: supabase start + db reset (seed 적용) 직후 실행.
import { assert, assertEquals } from "jsr:@std/assert@1";
import { createClient } from "npm:@supabase/supabase-js@2";
import { totpCode } from "../functions/_shared/totp.ts";

const URL = Deno.env.get("SUPABASE_URL") ?? "http://127.0.0.1:54321";
const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const CLASS_ID = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";
const TEACHER_ID = "11111111-1111-1111-1111-111111111111";
const STUDENT1 = "22222222-2222-2222-2222-222222222222"; // 동의O 멤버
const STUDENT4 = "55555555-5555-5555-5555-555555555555"; // 동의O 멤버
const STUDENT5 = "66666666-6666-6666-6666-666666666666"; // 동의O 멤버

const svc = createClient(URL, SERVICE, { auth: { persistSession: false } });

function itest(name: string, fn: () => Promise<void>) {
  Deno.test({ name, fn, sanitizeOps: false, sanitizeResources: false });
}

async function studentToken(email: string) {
  const client = createClient(URL, ANON, { auth: { persistSession: false } });
  const { data, error } = await client.auth.signInWithPassword({
    email,
    password: "password123",
  });
  if (error) throw new Error(`sign-in failed: ${error.message}`);
  return data.session!.access_token;
}

async function qrCheckIn(sessionId: string, jwt: string) {
  const { data: secret } = await svc
    .from("class_secrets")
    .select("qr_secret")
    .eq("class_id", CLASS_ID)
    .single();
  const code = await totpCode(secret!.qr_secret, {});
  const res = await fetch(`${URL}/functions/v1/check_in_qr`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${jwt}`,
      apikey: ANON,
    },
    body: JSON.stringify({ session_id: sessionId, code }),
  });
  return { status: res.status, body: await res.json() };
}

/** 시간창을 지정한 테스트용 세션 생성 (period 8~ 사용 — 다른 스위트와 충돌 방지) */
async function makeSession(args: {
  period: number;
  startedOffsetMin: number; // 시작 시각 = now + offset(분)
  closeOffsetMin: number | null;
  autoLateMinutes?: number | null;
}) {
  const now = Date.now();
  const { data, error } = await svc
    .from("sessions")
    .insert({
      class_id: CLASS_ID,
      teacher_id: TEACHER_ID,
      type: "PERIOD",
      period: args.period,
      mode: "BYOD",
      status: "ACTIVE",
      started_at: new Date(now + args.startedOffsetMin * 60_000).toISOString(),
      close_at: args.closeOffsetMin === null
        ? null
        : new Date(now + args.closeOffsetMin * 60_000).toISOString(),
      auto_late_after_minutes: args.autoLateMinutes ?? null,
    })
    .select("id")
    .single();
  if (error) throw new Error(`session insert failed: ${error.message}`);
  return data.id as string;
}

itest("①창 내 체크인 = present", async () => {
  const sessionId = await makeSession({
    period: 8,
    startedOffsetMin: 0,
    closeOffsetMin: 10,
  });
  const res = await qrCheckIn(sessionId, await studentToken("dummy-student1@example.com"));
  assertEquals(res.status, 200, JSON.stringify(res.body));
  assertEquals(res.body.record.status, "present");
});

itest("②지각 구간 체크인 = late (사유 미확정 null)", async () => {
  const sessionId = await makeSession({
    period: 9,
    startedOffsetMin: 0,
    closeOffsetMin: 10,
    autoLateMinutes: 0, // 시작 즉시 지각 구간 — 대기 없이 검증
  });
  const res = await qrCheckIn(sessionId, await studentToken("dummy-student4@example.com"));
  assertEquals(res.status, 200, JSON.stringify(res.body));
  assertEquals(res.body.record.status, "late");
  assertEquals(res.body.record.reason, null, "자동 지각은 사유 미확정 — 교사가 사후 확정");
});

itest("③close_at 경과 = 410 거부 ④연장(+5분) 후 재허용", async () => {
  const sessionId = await makeSession({
    period: 10,
    startedOffsetMin: -10, // 10분 전 시작
    closeOffsetMin: -5, // 5분 전 마감 — 이미 닫힘
  });
  const jwt = await studentToken("dummy-student5@example.com");

  const closed = await qrCheckIn(sessionId, jwt);
  assertEquals(closed.status, 410, JSON.stringify(closed.body));
  // cron 스윕이 먼저 돌면 session_not_active — 어느 쪽이든 창 밖 체크인은 거부된다
  assert(
    ["session_closed", "session_not_active"].includes(closed.body.error),
    `unexpected error: ${closed.body.error}`,
  );

  // 교사 "+5분 연장"에 해당: close_at을 미래로, (스윕됐다면) ACTIVE 복원
  const { error: extendError } = await svc
    .from("sessions")
    .update({
      close_at: new Date(Date.now() + 5 * 60_000).toISOString(),
      status: "ACTIVE",
      ended_at: null,
    })
    .eq("id", sessionId);
  assertEquals(extendError, null);

  const reopened = await qrCheckIn(sessionId, jwt);
  assertEquals(reopened.status, 200, JSON.stringify(reopened.body));
  assertEquals(reopened.body.record.status, "present");
});

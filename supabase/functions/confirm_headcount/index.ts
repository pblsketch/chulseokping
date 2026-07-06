// P0-3: 세션 마감 헤드카운트 확인 — 자동 출석 수는 서버가 집계한다(클라 값 불신).
// 불일치여도 차단 없음: CHECKIN_HEADCOUNT_GAP 플래그만 남기고 정정은 교사 수동 경로.
import {
  authedUserId,
  json,
  parseCheckInBody,
  serviceClient,
} from "../_shared/checkin.ts";

Deno.serve(async (req) => {
  const parsed = await parseCheckInBody(req);
  if ("error" in parsed) return parsed.error;
  const { body } = parsed;

  const svc = serviceClient();
  const teacherId = await authedUserId(svc, req);
  if (!teacherId) return json(401, { error: "unauthorized" });

  const sessionId = body.session_id as string | undefined;
  const matches = body.matches;
  const observedCount = body.observed_count as number | undefined;
  if (!sessionId || typeof matches !== "boolean") {
    return json(400, { error: "missing_fields" });
  }

  // 종료 직전(ACTIVE)뿐 아니라 스윕으로 이미 ENDED여도 확인은 유효 — 소유만 검증
  const { data: session } = await svc
    .from("sessions")
    .select("id, class_id, classes!inner(teacher_id)")
    .eq("id", sessionId)
    .eq("classes.teacher_id", teacherId)
    .maybeSingle();
  if (!session) return json(403, { error: "not_class_teacher" });

  // 자동 경로(QR/BLE)만 집계 — PIN/수동은 교사·키오스크가 이미 확인한 경로
  const { count: autoCount } = await svc
    .from("attendance_logs")
    .select("id", { count: "exact", head: true })
    .eq("session_id", sessionId)
    .in("method", ["QR", "BLE"]);

  const { error: updateError } = await svc
    .from("sessions")
    .update({ headcount_confirmed_at: new Date().toISOString() })
    .eq("id", sessionId);
  if (updateError) return json(500, { error: updateError.message });

  if (!matches) {
    const { error: flagError } = await svc.from("suspicious_flags").insert({
      session_id: sessionId,
      flag_type: "CHECKIN_HEADCOUNT_GAP",
      evidence: {
        auto_count: autoCount ?? 0,
        observed_count: observedCount ?? null,
      },
    });
    if (flagError) return json(500, { error: flagError.message });
  }

  return json(200, { auto_count: autoCount ?? 0 });
});

// TE-3 / BE-0: 교사 수동 출결 수정 — 쓰기는 이 함수(service role)만 수행한다.
// - record_id로 기존 행 갱신, 또는 (session_id, student_id)로 미출석자 행 생성(멱등 upsert, method=MANUAL)
// - 2축 검증: present→reason 없음 / 비출석→reason 필수 / reason_code는 출석인정에만
// - neis_excluded는 서버가 파생: reason_code=field_trip(교외체험학습)일 때만 true (ATTENDANCE_POLICY §5)
// - 동의 미확인 학생은 수동 입력도 거부 (PI-2 서버 강제)
import {
  consentAndMembershipGuard,
  json,
  loadActiveSession,
  parseCheckInBody,
  serviceClient,
} from "../_shared/checkin.ts";

const STATUSES = ["present", "late", "early_leave", "class_absent", "absent"];
const REASONS = ["recognized", "sick", "unrecognized", "other"];
const RECOGNIZED_CODES = [
  "family_event",
  "infectious_disease",
  "natural_disaster",
  "field_trip",
  "school_violence",
  "other_recognized",
];

Deno.serve(async (req) => {
  const parsed = await parseCheckInBody(req);
  if ("error" in parsed) return parsed.error;
  const { body } = parsed;

  const svc = serviceClient();

  // 교사 인증 (Authorization 헤더의 사용자 JWT)
  const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!token) return json(401, { error: "unauthorized" });
  const { data: userData, error: userError } = await svc.auth.getUser(token);
  if (userError || !userData.user) return json(401, { error: "unauthorized" });
  const teacherId = userData.user.id;

  const status = body.status as string | undefined;
  if (!status || !STATUSES.includes(status)) {
    return json(400, { error: "invalid_status" });
  }
  const reason = (body.reason as string | undefined) ?? null;
  const reasonCode = (body.reason_code as string | undefined) ?? null;
  const reasonDetail = (body.reason_detail as string | undefined) ?? null;
  const documentSubmitted = (body.document_submitted as boolean | undefined) ?? false;

  // 2축 모델 검증 (스키마 CHECK와 동일 — 클라이언트에 명확한 에러를 주기 위해 선검증)
  if (status === "present" && reason !== null) {
    return json(400, { error: "present_must_have_no_reason" });
  }
  if (status !== "present" && (reason === null || !REASONS.includes(reason))) {
    return json(400, { error: "reason_required" });
  }
  if (reasonCode !== null) {
    if (reason !== "recognized" || !RECOGNIZED_CODES.includes(reasonCode)) {
      return json(400, { error: "reason_code_only_for_recognized" });
    }
  }
  const neisExcluded = reasonCode === "field_trip"; // 서버 파생 — 클라이언트 값 무시

  const recordId = body.record_id as string | undefined;
  const sessionId = body.session_id as string | undefined;
  const studentId = body.student_id as string | undefined;

  const patch = {
    status,
    reason,
    reason_code: reasonCode,
    reason_detail: reasonDetail,
    document_submitted: documentSubmitted,
    neis_excluded: neisExcluded,
    updated_by: teacherId,
  };

  // 경로 A: 기존 행 갱신
  if (recordId) {
    const { data: record } = await svc
      .from("attendance_logs")
      .select("id, class_id")
      .eq("id", recordId)
      .maybeSingle();
    if (!record) return json(404, { error: "record_not_found" });

    const { count } = await svc
      .from("classes")
      .select("id", { count: "exact", head: true })
      .eq("id", record.class_id)
      .eq("teacher_id", teacherId);
    if ((count ?? 0) === 0) return json(403, { error: "not_class_teacher" });

    const { data: updated, error } = await svc
      .from("attendance_logs")
      .update(patch)
      .eq("id", recordId)
      .select()
      .single();
    if (error) return json(500, { error: error.message });
    return json(200, { created: false, record: updated });
  }

  // 경로 B: 미출석 학생 행 생성 (결석 처리 등) — unique(student,session) 멱등
  if (!sessionId || !studentId) return json(400, { error: "missing_fields" });

  const session = await loadActiveSession(svc, sessionId);
  if (!session) return json(410, { error: "session_not_active" });

  const { count } = await svc
    .from("classes")
    .select("id", { count: "exact", head: true })
    .eq("id", session.class_id)
    .eq("teacher_id", teacherId);
  if ((count ?? 0) === 0) return json(403, { error: "not_class_teacher" });

  const guard = await consentAndMembershipGuard(svc, studentId, session.class_id);
  if (guard) return guard;

  const { data: inserted, error: insertError } = await svc
    .from("attendance_logs")
    .insert({
      student_id: studentId,
      class_id: session.class_id,
      session_id: sessionId,
      method: "MANUAL",
      ...patch,
    })
    .select()
    .single();

  if (!insertError) return json(200, { created: true, record: inserted });
  if (insertError.code !== "23505") return json(500, { error: insertError.message });

  // 이미 행이 있으면 갱신으로 수렴 (멱등)
  const { data: updated, error: updateError } = await svc
    .from("attendance_logs")
    .update(patch)
    .eq("student_id", studentId)
    .eq("session_id", sessionId)
    .select()
    .single();
  if (updateError) return json(500, { error: updateError.message });
  return json(200, { created: false, record: updated });
});

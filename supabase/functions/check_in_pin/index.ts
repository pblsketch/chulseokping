// KO-4 / BE-2: 키오스크 PIN 체크인 — 기기 토큰 인증(사용자 JWT 없음) + 명단 매칭 + 멱등 INSERT.
// config.toml에서 verify_jwt=false (기기 토큰이 인증 수단).
import {
  consentAndMembershipGuard,
  idempotentCheckIn,
  json,
  loadActiveSession,
  parseCheckInBody,
  pinHash,
  serviceClient,
  sessionTimeVerdict,
} from "../_shared/checkin.ts";

Deno.serve(async (req) => {
  const parsed = await parseCheckInBody(req);
  if ("error" in parsed) return parsed.error;
  const { body } = parsed;

  const deviceToken = body.device_token as string | undefined;
  const sessionId = body.session_id as string | undefined;
  const studentNumber = body.student_number as string | undefined;
  const pin = body.pin as string | undefined;
  if (!deviceToken || !sessionId || !studentNumber || !pin) {
    return json(400, { error: "missing_fields" });
  }

  const svc = serviceClient();

  const { data: device } = await svc
    .from("kiosk_devices")
    .select("id, class_id")
    .eq("device_token", deviceToken)
    .eq("revoked", false)
    .maybeSingle();
  if (!device) return json(401, { error: "unknown_device" });

  const session = await loadActiveSession(svc, sessionId);
  if (!session) return json(410, { error: "session_not_active" });
  if (session.class_id !== device.class_id) return json(403, { error: "class_mismatch" });

  // P0-1: 수집 창 판정 — 서버 now() 기준
  const verdict = sessionTimeVerdict(session);
  if (verdict === "closed") return json(410, { error: "session_closed" });

  // 명단 매칭: 해당 class 소속 + 학번 일치 학생
  const { data: candidates } = await svc
    .from("profiles")
    .select("id, pin_hash, student_classes!inner(class_id)")
    .eq("role", "student")
    .eq("student_number", studentNumber)
    .eq("student_classes.class_id", session.class_id);
  const student = candidates?.[0];
  if (!student) return json(404, { error: "student_not_found" });

  if (!student.pin_hash || student.pin_hash !== (await pinHash(student.id, pin))) {
    return json(401, { error: "pin_mismatch" });
  }

  const guard = await consentAndMembershipGuard(svc, student.id, session.class_id);
  if (guard) return guard;

  const result = await idempotentCheckIn(svc, {
    studentId: student.id,
    classId: session.class_id,
    sessionId,
    method: "PIN",
    kioskDeviceId: device.id,
    status: verdict,
  });

  await svc
    .from("kiosk_devices")
    .update({ last_seen_at: new Date().toISOString() })
    .eq("id", device.id);

  return json(200, { created: result.created, record: result.record });
});

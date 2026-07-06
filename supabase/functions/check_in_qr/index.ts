// ST-4 / BE-1: 학생앱 회전 QR 체크인 — TOTP 서버 재검증(window ±1 = ±5s) 후 멱등 INSERT.
import { verifyTotpCode } from "../_shared/totp.ts";
import {
  authedUserId,
  consentAndMembershipGuard,
  idempotentCheckIn,
  json,
  loadActiveSession,
  parseCheckInBody,
  serviceClient,
  sessionTimeVerdict,
} from "../_shared/checkin.ts";
import { insertDeviceFlags, resolveCheckInDevice } from "../_shared/devices.ts";

Deno.serve(async (req) => {
  const parsed = await parseCheckInBody(req);
  if ("error" in parsed) return parsed.error;
  const { body } = parsed;

  const svc = serviceClient();
  const studentId = await authedUserId(svc, req);
  if (!studentId) return json(401, { error: "unauthorized" });

  const sessionId = body.session_id as string | undefined;
  const code = body.code as string | undefined;
  if (!sessionId || !code) return json(400, { error: "missing_fields" });

  const session = await loadActiveSession(svc, sessionId);
  if (!session) return json(410, { error: "session_not_active" });

  // P0-1: 수집 창 판정 — 서버 now() 기준 (cron 스윕이 늦어도 여기서 차단)
  const verdict = sessionTimeVerdict(session);
  if (verdict === "closed") return json(410, { error: "session_closed" });

  const { data: secret } = await svc
    .from("class_secrets")
    .select("qr_secret")
    .eq("class_id", session.class_id)
    .maybeSingle();
  if (!secret) return json(500, { error: "class_secret_missing" });

  const valid = await verifyTotpCode(secret.qr_secret, code, { window: 1 });
  if (!valid) return json(422, { error: "code_expired" }); // ST-4: "다시 스캔"

  const guard = await consentAndMembershipGuard(svc, studentId, session.class_id);
  if (guard) return guard;

  // P0-2: 기기 바인딩 판정 — 로그-온리, 어떤 경우에도 출석 기록은 진행
  const device = await resolveCheckInDevice(
    svc,
    studentId,
    body.device_uuid as string | undefined,
  );

  const result = await idempotentCheckIn(svc, {
    studentId,
    classId: session.class_id,
    sessionId,
    method: "QR",
    status: verdict,
    studentDeviceId: device.deviceId,
  });
  if (result.created) {
    await insertDeviceFlags(svc, {
      studentId,
      sessionId,
      attendanceLogId: result.record.id as string,
      flags: device.flags,
    });
  }
  return json(200, { created: result.created, record: result.record });
});

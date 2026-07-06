// ST-2/ST-3 / BE-3: BLE 근접 체크인 — 회전 minor(TOTP) + active session + 등록 기기 + class 매칭.
// payload는 (session_id, major, minor)만 — 좌표 수신 시 400 (PI-3).
import { verifyBeaconMinor } from "../_shared/totp.ts";
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
  const major = body.major as number | undefined;
  const minor = body.minor as number | undefined;
  if (!sessionId || typeof major !== "number" || typeof minor !== "number") {
    return json(400, { error: "missing_fields" });
  }

  const session = await loadActiveSession(svc, sessionId);
  if (!session) return json(410, { error: "session_not_active" });

  // P0-1: 수집 창 판정 — 서버 now() 기준
  const verdict = sessionTimeVerdict(session);
  if (verdict === "closed") return json(410, { error: "session_closed" });

  // 등록된(미revoke) 키오스크 기기 + class 매칭 (BE-3)
  const { data: device } = await svc
    .from("kiosk_devices")
    .select("id, beacon_secret")
    .eq("class_id", session.class_id)
    .eq("beacon_major", major)
    .eq("revoked", false)
    .maybeSingle();
  if (!device) return json(403, { error: "unknown_beacon" });

  const valid = await verifyBeaconMinor(device.beacon_secret, minor, { window: 1 });
  if (!valid) return json(422, { error: "minor_expired" });

  const guard = await consentAndMembershipGuard(svc, studentId, session.class_id);
  if (guard) return guard;

  // P0-2: 기기 바인딩 판정 — 로그-온리, 어떤 경우에도 출석 기록은 진행
  const boundDevice = await resolveCheckInDevice(
    svc,
    studentId,
    body.device_uuid as string | undefined,
  );

  const result = await idempotentCheckIn(svc, {
    studentId,
    classId: session.class_id,
    sessionId,
    method: "BLE",
    kioskDeviceId: device.id,
    status: verdict,
    studentDeviceId: boundDevice.deviceId,
  });
  if (result.created) {
    await insertDeviceFlags(svc, {
      studentId,
      sessionId,
      attendanceLogId: result.record.id as string,
      flags: boundDevice.flags,
    });
  }
  return json(200, { created: result.created, record: result.record });
});

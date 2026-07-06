// P0-2: 학생 기기 등록 — 최초 로그인 자동 active, 재바인딩은 pending(교사 원탭 승인 대기).
// device_uuid는 서버가 발급하고 클라이언트는 Keychain/Keystore에 보관한다.
import {
  authedUserId,
  json,
  parseCheckInBody,
  serviceClient,
} from "../_shared/checkin.ts";

const RAPID_REBIND_WINDOW_DAYS = 30;
const RAPID_REBIND_THRESHOLD = 2; // 30일 내 기존 등록 2건 이상이면 플래그

Deno.serve(async (req) => {
  const parsed = await parseCheckInBody(req);
  if ("error" in parsed) return parsed.error;
  const { body } = parsed;

  const svc = serviceClient();
  const studentId = await authedUserId(svc, req);
  if (!studentId) return json(401, { error: "unauthorized" });

  const platform = body.platform as string | undefined;
  const deviceModel = body.device_model as string | undefined;
  const appSetId = body.app_set_id as string | undefined;
  const knownUuid = body.device_uuid as string | undefined;
  if (platform !== "android" && platform !== "ios") {
    return json(400, { error: "invalid_platform" });
  }

  const { data: profile } = await svc
    .from("profiles")
    .select("role")
    .eq("id", studentId)
    .maybeSingle();
  if (!profile || profile.role !== "student") {
    return json(403, { error: "not_a_student" });
  }

  // 같은 기기의 재로그인: 보관된 uuid가 본인 기기면 그대로 반환 (멱등)
  if (knownUuid) {
    const { data: known } = await svc
      .from("student_devices")
      .select("id, device_uuid, status")
      .eq("device_uuid", knownUuid)
      .eq("student_id", studentId)
      .maybeSingle();
    if (known && known.status !== "revoked") {
      return json(200, {
        device_uuid: known.device_uuid,
        status: known.status,
      });
    }
    // revoked/타인/미존재 → 새 등록 플로우로 (회수된 기기는 재승인 필요)
  }

  const { data: active } = await svc
    .from("student_devices")
    .select("id")
    .eq("student_id", studentId)
    .eq("status", "active")
    .maybeSingle();

  const status = active ? "pending" : "active"; // 최초는 무마찰 자동 등록
  const { data: created, error: insertError } = await svc
    .from("student_devices")
    .insert({
      student_id: studentId,
      platform,
      device_model: deviceModel ?? null,
      app_set_id: appSetId ?? null,
      status,
    })
    .select("id, device_uuid, status, registered_at")
    .single();
  if (insertError) return json(500, { error: insertError.message });

  // 로그-온리 신호 (차단 없음)
  if (status === "pending") {
    const since = new Date(
      Date.now() - RAPID_REBIND_WINDOW_DAYS * 86_400_000,
    ).toISOString();
    const { count } = await svc
      .from("student_devices")
      .select("id", { count: "exact", head: true })
      .eq("student_id", studentId)
      .gte("registered_at", since)
      .neq("id", created.id);
    if ((count ?? 0) >= RAPID_REBIND_THRESHOLD) {
      await svc.from("suspicious_flags").insert({
        student_id: studentId,
        flag_type: "RAPID_DEVICE_REBIND",
        evidence: { recent_registrations: count, window_days: RAPID_REBIND_WINDOW_DAYS },
      });
    }
  }
  if (appSetId) {
    // 형제 공유 기기는 정상 케이스가 많다 — 차단 금지, 신호만
    const { data: shared } = await svc
      .from("student_devices")
      .select("student_id")
      .eq("app_set_id", appSetId)
      .neq("student_id", studentId)
      .limit(1);
    if (shared && shared.length > 0) {
      await svc.from("suspicious_flags").insert({
        student_id: studentId,
        flag_type: "SHARED_DEVICE",
        evidence: { other_student_id: shared[0].student_id },
      });
    }
  }

  return json(200, {
    device_uuid: created.device_uuid,
    status: created.status,
  });
});

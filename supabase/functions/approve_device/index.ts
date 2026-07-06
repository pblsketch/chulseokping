// P0-2: 교사 기기 승인/회수 — 재바인딩의 본인 인증은 "눈앞의 학생을 아는 교사"다.
// approve: pending → active (기존 active는 revoked + replaced_by). revoke: 분실 등 즉시 회수.
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

  const deviceId = body.device_id as string | undefined;
  const action = body.action as string | undefined;
  if (!deviceId || (action !== "approve" && action !== "revoke")) {
    return json(400, { error: "missing_fields" });
  }

  const { data: device } = await svc
    .from("student_devices")
    .select("id, student_id, status")
    .eq("id", deviceId)
    .maybeSingle();
  if (!device) return json(404, { error: "device_not_found" });

  // 담당 학생인지 검증 (set_student_pin과 동일 계약)
  const { count } = await svc
    .from("student_classes")
    .select("student_id, classes!inner(teacher_id)", {
      count: "exact",
      head: true,
    })
    .eq("student_id", device.student_id)
    .eq("classes.teacher_id", teacherId);
  if ((count ?? 0) === 0) return json(403, { error: "not_your_student" });

  const now = new Date().toISOString();

  if (action === "revoke") {
    if (device.status === "revoked") return json(200, { ok: true });
    const { error } = await svc
      .from("student_devices")
      .update({ status: "revoked", revoked_at: now, revoked_by: teacherId })
      .eq("id", device.id);
    if (error) return json(500, { error: error.message });
    return json(200, { ok: true });
  }

  // approve
  if (device.status !== "pending") {
    return json(409, { error: "not_pending" });
  }
  // 기존 active를 먼저 내려야 학생당 active 1대 불변식(unique partial index)을 지킨다
  const { error: retireError } = await svc
    .from("student_devices")
    .update({
      status: "revoked",
      revoked_at: now,
      revoked_by: teacherId,
      replaced_by: device.id,
    })
    .eq("student_id", device.student_id)
    .eq("status", "active");
  if (retireError) return json(500, { error: retireError.message });

  const { error: activateError } = await svc
    .from("student_devices")
    .update({ status: "active" })
    .eq("id", device.id);
  if (activateError) return json(500, { error: activateError.message });

  return json(200, { ok: true });
});

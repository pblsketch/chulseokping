// TE-6: 교사가 담당 학생의 키오스크 PIN을 발급/재설정한다.
// pin_hash만 저장(평문 금지). 해시 방식은 check_in_pin과 동일 계약 (_shared pinHash).
import { json, parseCheckInBody, pinHash, serviceClient } from "../_shared/checkin.ts";

Deno.serve(async (req) => {
  const parsed = await parseCheckInBody(req);
  if ("error" in parsed) return parsed.error;
  const { body } = parsed;

  const svc = serviceClient();

  const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!token) return json(401, { error: "unauthorized" });
  const { data: userData, error: userError } = await svc.auth.getUser(token);
  if (userError || !userData.user) return json(401, { error: "unauthorized" });
  const teacherId = userData.user.id;

  const studentId = body.student_id as string | undefined;
  const pin = body.pin as string | undefined;
  if (!studentId || !pin) return json(400, { error: "missing_fields" });
  if (!/^\d{4,8}$/.test(pin)) return json(400, { error: "pin_must_be_4_to_8_digits" });

  // 담당 학생인지 검증 (student_classes × classes.teacher_id)
  const { count } = await svc
    .from("student_classes")
    .select("student_id, classes!inner(teacher_id)", {
      count: "exact",
      head: true,
    })
    .eq("student_id", studentId)
    .eq("classes.teacher_id", teacherId);
  if ((count ?? 0) === 0) return json(403, { error: "not_your_student" });

  const { error: updateError } = await svc
    .from("profiles")
    .update({ pin_hash: await pinHash(studentId, pin) })
    .eq("id", studentId)
    .eq("role", "student");
  if (updateError) return json(500, { error: updateError.message });

  return json(200, { ok: true });
});

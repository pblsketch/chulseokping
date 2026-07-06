// M5: 담임이 학생 연결 코드를 재발급한다 — 학생용 "비밀번호 재설정"에 해당.
// 기존 활성 코드는 전부 무효화하고 새 코드 1개만 살아있게 한다.
import {
  authedUserId,
  json,
  parseCheckInBody,
  serviceClient,
} from "../_shared/checkin.ts";
import {
  formatLinkCode,
  generateLinkCode,
  linkCodeExpiry,
  sha256Hex,
} from "../_shared/accounts.ts";

Deno.serve(async (req) => {
  const parsed = await parseCheckInBody(req);
  if ("error" in parsed) return parsed.error;
  const { body } = parsed;

  const svc = serviceClient();

  const teacherId = await authedUserId(svc, req);
  if (!teacherId) return json(401, { error: "unauthorized" });

  const studentId = body.student_id as string | undefined;
  if (!studentId) return json(400, { error: "missing_fields" });

  // 담당 학생인지 검증 (set_student_pin과 동일 계약)
  const { count } = await svc
    .from("student_classes")
    .select("student_id, classes!inner(teacher_id)", {
      count: "exact",
      head: true,
    })
    .eq("student_id", studentId)
    .eq("classes.teacher_id", teacherId);
  if ((count ?? 0) === 0) return json(403, { error: "not_your_student" });

  const { error: revokeError } = await svc
    .from("student_link_codes")
    .update({ used_at: new Date().toISOString() })
    .eq("student_id", studentId)
    .is("used_at", null);
  if (revokeError) return json(500, { error: revokeError.message });

  const code = generateLinkCode();
  const expiresAt = linkCodeExpiry();
  const { error: insertError } = await svc.from("student_link_codes").insert({
    student_id: studentId,
    code_hash: await sha256Hex(code),
    issued_by: teacherId,
    expires_at: expiresAt,
  });
  if (insertError) return json(500, { error: insertError.message });

  return json(200, { link_code: formatLinkCode(code), expires_at: expiresAt });
});

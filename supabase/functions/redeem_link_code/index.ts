// M5: 학생이 연결 코드를 교환해 로그인 자격을 얻는다 (무인증 — 코드 자체가 자격 증명).
// 교환 시 내부 비밀번호를 회전시켜 1회용 자격을 만들고 코드를 소모 처리한다.
// 이전에 연결된 기기의 저장 자격은 죽고, 살아있는 세션은 refresh token으로 유지된다.
import { json, parseCheckInBody, serviceClient } from "../_shared/checkin.ts";
import {
  isValidLinkCodeFormat,
  normalizeLinkCode,
  randomPassword,
  sha256Hex,
} from "../_shared/accounts.ts";

Deno.serve(async (req) => {
  const parsed = await parseCheckInBody(req);
  if ("error" in parsed) return parsed.error;
  const { body } = parsed;

  const raw = body.code as string | undefined;
  if (!raw) return json(400, { error: "missing_fields" });
  const code = normalizeLinkCode(raw);
  if (!isValidLinkCodeFormat(code)) {
    return json(400, { error: "invalid_code_format" });
  }

  const svc = serviceClient();

  const { data: row } = await svc
    .from("student_link_codes")
    .select("id, student_id, expires_at, used_at")
    .eq("code_hash", await sha256Hex(code))
    .maybeSingle();
  // 존재/만료/사용됨을 구분해 알려주지 않는다 — 코드 추측 피드백 최소화
  if (!row || row.used_at !== null || new Date(row.expires_at) <= new Date()) {
    return json(404, { error: "invalid_or_expired_code" });
  }

  const { data: profile } = await svc
    .from("profiles")
    .select("id, role")
    .eq("id", row.student_id)
    .eq("role", "student")
    .maybeSingle();
  if (!profile) return json(404, { error: "invalid_or_expired_code" });

  // 코드 소모를 먼저 확정한다 — 동시 교환 경쟁에서 한 요청만 성공
  const { data: consumed, error: consumeError } = await svc
    .from("student_link_codes")
    .update({ used_at: new Date().toISOString() })
    .eq("id", row.id)
    .is("used_at", null)
    .select("id");
  if (consumeError) return json(500, { error: consumeError.message });
  if (!consumed || consumed.length === 0) {
    return json(404, { error: "invalid_or_expired_code" });
  }

  const password = randomPassword();
  const { data: updated, error: updateError } = await svc.auth.admin
    .updateUserById(row.student_id, { password });
  if (updateError || !updated.user?.email) {
    return json(500, { error: "credential_rotation_failed" });
  }

  return json(200, { email: updated.user.email, password });
});

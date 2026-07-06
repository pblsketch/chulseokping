// M6: 학급 생성 — classes + class_secrets(QR TOTP secret) 동시 발급.
// 클라이언트 직접 INSERT는 RLS에서 차단됨(20260706000004) — secret 없는 학급(QR 조용히 실패) 방지.
import {
  authedUserId,
  json,
  parseCheckInBody,
  serviceClient,
} from "../_shared/checkin.ts";
import { generateInviteCode, randomHexSecret } from "../_shared/accounts.ts";

const INVITE_RETRY = 3;

Deno.serve(async (req) => {
  const parsed = await parseCheckInBody(req);
  if ("error" in parsed) return parsed.error;
  const { body } = parsed;

  const svc = serviceClient();

  const teacherId = await authedUserId(svc, req);
  if (!teacherId) return json(401, { error: "unauthorized" });

  const name = typeof body.name === "string" ? body.name.trim() : "";
  if (!name || name.length > 30) return json(400, { error: "invalid_name" });

  // 교사만 학급 생성 (학생 계정의 학급 소유 방지)
  const { data: profile } = await svc
    .from("profiles")
    .select("role, school_id")
    .eq("id", teacherId)
    .maybeSingle();
  if (!profile || profile.role !== "teacher") {
    return json(403, { error: "not_a_teacher" });
  }

  // invite_code unique 충돌 시 재시도
  let cls: Record<string, unknown> | null = null;
  let lastError = "";
  for (let attempt = 0; attempt < INVITE_RETRY && !cls; attempt++) {
    const { data, error } = await svc
      .from("classes")
      .insert({
        teacher_id: teacherId,
        school_id: profile.school_id,
        name,
        invite_code: generateInviteCode(),
      })
      .select()
      .single();
    if (error) {
      lastError = error.message;
      if (error.code !== "23505") break; // unique 충돌 외에는 재시도 무의미
      continue;
    }
    cls = data;
  }
  if (!cls) return json(500, { error: `class_insert_failed: ${lastError}` });

  // secret 동시 발급 — 실패 시 학급을 남기지 않는다 (QR 불능 학급 방지)
  const { error: secretError } = await svc.from("class_secrets").insert({
    class_id: cls.id,
    qr_secret: randomHexSecret(),
  });
  if (secretError) {
    await svc.from("classes").delete().eq("id", cls.id as string);
    return json(500, { error: `secret_insert_failed: ${secretError.message}` });
  }

  return json(200, { class: cls });
});

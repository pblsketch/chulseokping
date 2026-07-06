// M5: 교사가 학생 계정을 일괄 생성한다 (하이브리드 모델의 기본 경로).
// 내부 이메일 + 랜덤 비밀번호로 auth 사용자 생성(service role) → profiles/student_classes/
// (선택) consents 기록 → 연결 코드 발급. 학생은 연결 코드로만 로그인한다.
import {
  authedUserId,
  json,
  parseCheckInBody,
  serviceClient,
} from "../_shared/checkin.ts";
import {
  formatLinkCode,
  generateLinkCode,
  internalStudentEmail,
  linkCodeExpiry,
  randomPassword,
  sha256Hex,
} from "../_shared/accounts.ts";

const MAX_STUDENTS_PER_CALL = 60;

interface StudentInput {
  name?: unknown;
  student_number?: unknown;
  guardian_consented?: unknown;
}

Deno.serve(async (req) => {
  const parsed = await parseCheckInBody(req);
  if ("error" in parsed) return parsed.error;
  const { body } = parsed;

  const svc = serviceClient();

  const teacherId = await authedUserId(svc, req);
  if (!teacherId) return json(401, { error: "unauthorized" });

  const classId = body.class_id as string | undefined;
  const students = body.students as StudentInput[] | undefined;
  const policyVersion = (body.policy_version as string | undefined) ?? "v1";
  if (!classId || !Array.isArray(students) || students.length === 0) {
    return json(400, { error: "missing_fields" });
  }
  if (students.length > MAX_STUDENTS_PER_CALL) {
    return json(400, { error: "too_many_students", max: MAX_STUDENTS_PER_CALL });
  }

  // 학급 소유 검증 + school_id 상속
  const { data: cls } = await svc
    .from("classes")
    .select("id, school_id, teacher_id")
    .eq("id", classId)
    .eq("teacher_id", teacherId)
    .maybeSingle();
  if (!cls) return json(403, { error: "not_your_class" });

  // 학급 내 학번 중복 방지용 기존 명단
  const { data: existingRows } = await svc
    .from("profiles")
    .select("student_number, student_classes!inner(class_id)")
    .eq("student_classes.class_id", classId);
  const existingNumbers = new Set(
    (existingRows ?? []).map((r) => r.student_number as string | null),
  );

  const results: Record<string, unknown>[] = [];
  for (const input of students) {
    const name = typeof input.name === "string" ? input.name.trim() : "";
    const studentNumber = typeof input.student_number === "string"
      ? input.student_number.trim()
      : "";
    const consented = input.guardian_consented === true;

    const fail = (error: string) =>
      results.push({ ok: false, name, student_number: studentNumber, error });

    if (!name || name.length > 50) {
      fail("invalid_name");
      continue;
    }
    if (!/^\d{1,10}$/.test(studentNumber)) {
      fail("invalid_student_number");
      continue;
    }
    if (existingNumbers.has(studentNumber)) {
      fail("duplicate_student_number");
      continue;
    }

    const { data: created, error: createError } = await svc.auth.admin
      .createUser({
        email: internalStudentEmail(),
        password: randomPassword(),
        email_confirm: true, // 내부 계정 — 수신 불가 주소라 확인 절차 없음
      });
    if (createError || !created.user) {
      fail(`auth_create_failed: ${createError?.message ?? "unknown"}`);
      continue;
    }
    const studentId = created.user.id;

    // 이후 단계 실패 시 auth 사용자를 남기지 않는다 (고아 계정 방지)
    const rollback = () => svc.auth.admin.deleteUser(studentId);

    const { error: profileError } = await svc.from("profiles").insert({
      id: studentId,
      role: "student",
      name,
      student_number: studentNumber,
      school_id: cls.school_id,
    });
    if (profileError) {
      await rollback();
      fail(`profile_insert_failed: ${profileError.message}`);
      continue;
    }

    const { error: memberError } = await svc.from("student_classes").insert({
      student_id: studentId,
      class_id: classId,
    });
    if (memberError) {
      await rollback();
      fail(`membership_insert_failed: ${memberError.message}`);
      continue;
    }

    if (consented) {
      const { error: consentError } = await svc.from("consents").insert({
        student_id: studentId,
        policy_version: policyVersion,
        guardian_confirmed_by: teacherId,
      });
      if (consentError) {
        await rollback();
        fail(`consent_insert_failed: ${consentError.message}`);
        continue;
      }
    }

    const code = generateLinkCode();
    const { error: codeError } = await svc.from("student_link_codes").insert({
      student_id: studentId,
      code_hash: await sha256Hex(code),
      issued_by: teacherId,
      expires_at: linkCodeExpiry(),
    });
    if (codeError) {
      await rollback();
      fail(`link_code_failed: ${codeError.message}`);
      continue;
    }

    existingNumbers.add(studentNumber);
    results.push({
      ok: true,
      student_id: studentId,
      name,
      student_number: studentNumber,
      link_code: formatLinkCode(code),
      guardian_consented: consented,
    });
  }

  return json(200, { students: results });
});

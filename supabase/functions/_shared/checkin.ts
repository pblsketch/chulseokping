// 출석 체크인 공통 로직 (BE-0~BE-3, PI-2, PI-3)
// 계약: 쓰기는 service role 전용 / 좌표 수신 즉시 거부 / 동의 미확인 403 / 멱등(학생×세션 1행).

import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

export function serviceClient(): SupabaseClient {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );
}

export function json(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

// PI-3: 좌표성 키는 payload 어디에도 못 들어온다. 발견 즉시 400 + 경보 로그.
const FORBIDDEN_KEYS = new Set([
  "lat", "lng", "latitude", "longitude", "coords", "coordinates",
  "location", "gps", "geolocation", "position", "accuracy",
]);

/** 중첩 객체 포함 좌표성 키 탐지. 발견 시 해당 키 반환, 없으면 null. */
export function findCoordinateKey(value: unknown, depth = 0): string | null {
  if (depth > 4 || value === null || typeof value !== "object") return null;
  for (const [key, child] of Object.entries(value as Record<string, unknown>)) {
    if (FORBIDDEN_KEYS.has(key.toLowerCase())) return key;
    const nested = findCoordinateKey(child, depth + 1);
    if (nested) return nested;
  }
  return null;
}

/** 공통 요청 게이트: POST + JSON + 좌표 거부. 실패 시 에러 Response 반환. */
export async function parseCheckInBody(
  req: Request,
): Promise<{ body: Record<string, unknown> } | { error: Response }> {
  if (req.method !== "POST") {
    return { error: json(405, { error: "method_not_allowed" }) };
  }
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return { error: json(400, { error: "invalid_json" }) };
  }
  const coordKey = findCoordinateKey(body);
  if (coordKey) {
    console.error(`[ALERT][PI-3] coordinate key rejected: ${coordKey}`); // 좌표 저장 시도 즉시 경보
    return { error: json(400, { error: "coordinates_forbidden", key: coordKey }) };
  }
  return { body };
}

/** 공통 정책 게이트: 동의(PI-2) → 멤버십(BE-2). 위반 시 403 Response, 통과 시 null. */
export async function consentAndMembershipGuard(
  svc: SupabaseClient,
  studentId: string,
  classId: string,
): Promise<Response | null> {
  if (!(await hasConsent(svc, studentId))) {
    return json(403, { error: "consent_required" });
  }
  if (!(await isMember(svc, studentId, classId))) {
    return json(403, { error: "not_a_member" });
  }
  return null;
}

/** Authorization 헤더의 JWT로 호출 학생 식별 (QR/BLE 경로) */
export async function authedUserId(
  svc: SupabaseClient,
  req: Request,
): Promise<string | null> {
  const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!token) return null;
  const { data, error } = await svc.auth.getUser(token);
  if (error || !data.user) return null;
  return data.user.id;
}

export interface ActiveSession {
  id: string;
  class_id: string;
  type: "HOMEROOM" | "PERIOD";
  period: number | null;
  status: string;
}

/** 활성 세션 로드 (BE-5: ENDED 세션 거부) */
export async function loadActiveSession(
  svc: SupabaseClient,
  sessionId: string,
): Promise<ActiveSession | null> {
  const { data } = await svc
    .from("sessions")
    .select("id, class_id, type, period, status")
    .eq("id", sessionId)
    .eq("status", "ACTIVE")
    .maybeSingle();
  return data as ActiveSession | null;
}

/** 학급의 현재 활성 세션 (키오스크 sync용) */
export async function loadActiveSessionOfClass(
  svc: SupabaseClient,
  classId: string,
): Promise<ActiveSession | null> {
  const { data } = await svc
    .from("sessions")
    .select("id, class_id, type, period, status")
    .eq("class_id", classId)
    .eq("status", "ACTIVE")
    .order("started_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  return data as ActiveSession | null;
}

/** PI-2: 동의 미확인 학생은 서버가 수집 거부 */
export async function hasConsent(
  svc: SupabaseClient,
  studentId: string,
): Promise<boolean> {
  const { count } = await svc
    .from("consents")
    .select("id", { count: "exact", head: true })
    .eq("student_id", studentId);
  return (count ?? 0) > 0;
}

/** BE-2: 세션 학급 명단(student_classes) 멤버십 검증 */
export async function isMember(
  svc: SupabaseClient,
  studentId: string,
  classId: string,
): Promise<boolean> {
  const { count } = await svc
    .from("student_classes")
    .select("student_id", { count: "exact", head: true })
    .eq("student_id", studentId)
    .eq("class_id", classId);
  return (count ?? 0) > 0;
}

export interface CheckInResult {
  created: boolean;
  record: Record<string, unknown>;
}

/**
 * 멱등 체크인: unique(student_id, session_id) 충돌 시 기존 행 반환(새 행 없음).
 * 다른 method로의 중복 시도는 suspicious_flags에 로그-온리 기록 (PRD §7).
 */
export async function idempotentCheckIn(
  svc: SupabaseClient,
  args: {
    studentId: string;
    classId: string;
    sessionId: string;
    method: "QR" | "PIN" | "BLE" | "MANUAL" | "LIST";
    kioskDeviceId?: string;
  },
): Promise<CheckInResult> {
  const { data: inserted, error } = await svc
    .from("attendance_logs")
    .insert({
      student_id: args.studentId,
      class_id: args.classId,
      session_id: args.sessionId,
      method: args.method,
      status: "present",
      kiosk_device_id: args.kioskDeviceId ?? null,
    })
    .select()
    .single();

  if (!error) return { created: true, record: inserted };
  if (error.code !== "23505") throw new Error(`insert failed: ${error.message}`);

  const { data: existing, error: fetchError } = await svc
    .from("attendance_logs")
    .select()
    .eq("student_id", args.studentId)
    .eq("session_id", args.sessionId)
    .single();
  if (fetchError) throw new Error(`idempotent fetch failed: ${fetchError.message}`);

  if (existing.method !== args.method) {
    await svc.from("suspicious_flags").insert({
      attendance_log_id: existing.id,
      session_id: args.sessionId,
      student_id: args.studentId,
      flag_type: "duplicate_method",
      evidence: { first_method: existing.method, retry_method: args.method },
    });
  }
  return { created: false, record: existing };
}

/** M0 더미용 PIN 해시 (sha256 hex of "studentId:pin"). 실운영 전 KDF로 교체 대상. */
export async function pinHash(studentId: string, pin: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(`${studentId}:${pin}`),
  );
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

// P0-2 기기 바인딩 공통 (RESEARCH_DEVICE_BINDING §B-1, B-2)
// 계약: 차단 없음 — 미바인딩/타인 기기여도 출석은 기록하고 suspicious_flags만 남긴다(로그-온리).
import type { SupabaseClient } from "npm:@supabase/supabase-js@2";

export interface DeviceRow {
  id: string;
  student_id: string;
  status: "active" | "pending" | "revoked";
}

export interface DeviceResolution {
  /** attendance_logs.student_device_id에 붙일 값 (본인 기기일 때만) */
  deviceId: string | null;
  /** 체크인 기록 후 삽입할 로그-온리 플래그 (attendance_log_id는 호출부가 채움) */
  flags: { flag_type: string; evidence: Record<string, unknown> }[];
}

/** 체크인 시점 기기 판정 — deviceUuid 미제공(구버전 클라)은 무플래그 통과 */
export async function resolveCheckInDevice(
  svc: SupabaseClient,
  studentId: string,
  deviceUuid: string | undefined,
): Promise<DeviceResolution> {
  if (!deviceUuid) return { deviceId: null, flags: [] };

  const { data } = await svc
    .from("student_devices")
    .select("id, student_id, status")
    .eq("device_uuid", deviceUuid)
    .maybeSingle();
  const device = data as DeviceRow | null;

  if (!device) {
    return {
      deviceId: null,
      flags: [{
        flag_type: "UNBOUND_DEVICE_CHECKIN",
        evidence: { device_status: "unknown" },
      }],
    };
  }
  if (device.student_id !== studentId) {
    // 서버 발급 UUID는 학생별 유일 — 타인 UUID 제시 = 같은 기기로 복수 계정 의심
    return {
      deviceId: null,
      flags: [{
        flag_type: "MULTI_ACCOUNT_SAME_DEVICE",
        evidence: { device_owner_student_id: device.student_id },
      }],
    };
  }
  if (device.status !== "active") {
    return {
      deviceId: device.id,
      flags: [{
        flag_type: "UNBOUND_DEVICE_CHECKIN",
        evidence: { device_status: device.status },
      }],
    };
  }
  return { deviceId: device.id, flags: [] };
}

/** 판정 플래그 기록 — 재시도 스팸 방지를 위해 신규 기록(created)일 때만 호출할 것 */
export async function insertDeviceFlags(
  svc: SupabaseClient,
  args: {
    studentId: string;
    sessionId: string;
    attendanceLogId: string | null;
    flags: DeviceResolution["flags"];
  },
): Promise<void> {
  if (args.flags.length === 0) return;
  await svc.from("suspicious_flags").insert(
    args.flags.map((f) => ({
      attendance_log_id: args.attendanceLogId,
      session_id: args.sessionId,
      student_id: args.studentId,
      flag_type: f.flag_type,
      evidence: f.evidence,
    })),
  );
}

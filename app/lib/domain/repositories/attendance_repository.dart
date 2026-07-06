import '../../core/result/result.dart';
import '../entities/attendance_record.dart';
import '../entities/suspicious_flag.dart';
import '../value_objects/absence_reason.dart';
import '../value_objects/attendance_status.dart';

/// 출결 저장소 인터페이스.
/// 계약(BE-0): 모든 쓰기는 구현체가 검증 Edge Function을 경유한다 — 직접 INSERT 금지.
abstract interface class AttendanceRepository {
  /// QR 체크인 — check_in_qr Edge Function 호출
  Future<Result<AttendanceRecord>> checkInByQr({
    required String sessionId,
    required String code,
  });

  /// BLE 체크인 — check_in_ble Edge Function 호출. payload는 근접 식별자만(좌표 금지).
  Future<Result<AttendanceRecord>> checkInByBle({
    required String sessionId,
    required int major,
    required int minor,
  });

  /// 교사 수동 상태 수정 (기존 행) — update_attendance Edge Function
  Future<Result<AttendanceRecord>> updateStatus({
    required String recordId,
    required AttendanceStatus status,
    AbsenceReason? reason,
    RecognizedCode? reasonCode,
    String? reasonDetail,
  });

  /// 교사 수동 기록 (미출석 학생 결석 처리 등, method=MANUAL) — update_attendance Edge Function
  Future<Result<AttendanceRecord>> markManual({
    required String sessionId,
    required String studentId,
    required AttendanceStatus status,
    AbsenceReason? reason,
    RecognizedCode? reasonCode,
    String? reasonDetail,
  });

  /// 세션 실시간 출결 스트림 (Realtime)
  Stream<List<AttendanceRecord>> watchSession(String sessionId);

  /// 학생 본인의 세션 출석 기록 실시간 스트림 (미출석이면 null).
  /// QR/BLE/키오스크 어느 경로로 출석해도 홈 화면이 즉시 "출석됨"으로 바뀐다 (ST-4).
  Stream<AttendanceRecord?> watchMyRecord(String sessionId);

  /// 월별 조회 (나이스 일람표·내보내기 원천)
  Future<Result<List<AttendanceRecord>>> monthlyRecords({
    required String classId,
    required int year,
    required int month,
  });

  // ── P0-3 헤드카운트·의심 신호 ──

  /// 세션 마감 헤드카운트 확인 — confirm_headcount Edge Function.
  /// 집계는 서버가 하고, 불일치는 로그-온리 플래그로만 남는다.
  Future<Result<void>> confirmHeadcount({
    required String sessionId,
    required bool matches,
    int? observedCount,
  });

  /// 세션의 의심 신호 목록 (RLS: 담당 교사만)
  Future<Result<List<SuspiciousFlag>>> sessionFlags(String sessionId);

  /// 의심 신호 확인 처리 (reviewed=true)
  Future<Result<void>> markFlagReviewed(String flagId);
}

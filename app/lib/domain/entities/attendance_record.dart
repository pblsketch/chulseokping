import '../value_objects/absence_reason.dart';
import '../value_objects/attendance_status.dart';
import '../value_objects/check_in_mode.dart';

/// 출결 기록 — 학생 × 세션 1행 (PRD §3 멱등 계약).
/// 좌표(lat/lng) 필드는 어떤 형태로도 추가 금지 (PI-3, 회귀 테스트로 고정).
class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.sessionId,
    required this.method,
    required this.status,
    required this.checkInTime,
    this.reason,
    this.reasonCode,
    this.reasonDetail,
    this.documentSubmitted = false,
    this.neisExcluded = false,
    this.kioskDeviceId,
    this.updatedAt,
    this.updatedBy,
  }) : assert(
         status == AttendanceStatus.present ? reason == null : reason != null,
         '출석이 아닌 상태에는 사유가 필수, 출석에는 사유 없음 (2축 모델)',
       );

  final String id;
  final String studentId;
  final String classId;
  final String sessionId;
  final CheckInMode method;
  final AttendanceStatus status;
  final AbsenceReason? reason;
  final RecognizedCode? reasonCode;
  final String? reasonDetail;

  /// 질병결석 증빙(진단서/의견서, D+5) 제출 여부 (ATTENDANCE_POLICY §6)
  final bool documentSubmitted;

  /// 교외체험학습: 출석인정 + 학생부 미기재 → NEIS 내보내기 제외 (§5)
  final bool neisExcluded;
  final String? kioskDeviceId;
  final DateTime checkInTime;
  final DateTime? updatedAt;
  final String? updatedBy;
}

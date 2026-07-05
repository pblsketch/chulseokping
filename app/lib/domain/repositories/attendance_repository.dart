import '../../core/result/result.dart';
import '../entities/attendance_record.dart';
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

  /// 교사 수동 상태 수정 (M1 — Edge Function 경유)
  Future<Result<AttendanceRecord>> updateStatus({
    required String recordId,
    required AttendanceStatus status,
    AbsenceReason? reason,
    String? reasonDetail,
  });

  /// 세션 실시간 출결 스트림 (Realtime)
  Stream<List<AttendanceRecord>> watchSession(String sessionId);

  /// 월별 조회 (나이스 일람표·내보내기 원천)
  Future<Result<List<AttendanceRecord>>> monthlyRecords({
    required String classId,
    required int year,
    required int month,
  });
}

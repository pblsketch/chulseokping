import '../../core/error/failure.dart';
import '../../core/result/result.dart';
import '../entities/attendance_record.dart';
import '../repositories/attendance_repository.dart';
import '../value_objects/check_in_mode.dart';

/// P0-3: 세션 마감 헤드카운트 — 대리출석(폰 2대)의 유일한 실효 대책은 교사 육안 확인.
/// 정본 집계는 서버가 다시 한다 — [autoCount]는 다이얼로그 표시용.
class ConfirmHeadcount {
  const ConfirmHeadcount(this._repository);

  final AttendanceRepository _repository;

  /// 자동 경로(QR/BLE)만 집계 — PIN/수동은 사람이 이미 확인한 경로
  static int autoCount(List<AttendanceRecord> records) => records
      .where((r) => r.method == CheckInMode.qr || r.method == CheckInMode.ble)
      .length;

  Future<Result<void>> call({
    required String sessionId,
    required bool matches,
    int? observedCount,
  }) {
    if (observedCount != null && (observedCount < 0 || observedCount > 999)) {
      return Future.value(const Err(ValidationFailure('인원수는 0~999예요')));
    }
    return _repository.confirmHeadcount(
      sessionId: sessionId,
      matches: matches,
      observedCount: observedCount,
    );
  }
}

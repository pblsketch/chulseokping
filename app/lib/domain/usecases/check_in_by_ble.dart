import '../../core/error/failure.dart';
import '../../core/result/result.dart';
import '../entities/attendance_record.dart';
import '../repositories/attendance_repository.dart';

/// ST-2/ST-3: BLE 근접 자동 출석. 입력은 근접 식별자(major/회전 minor)만 — 좌표 금지.
class CheckInByBle {
  const CheckInByBle(this._repository);

  final AttendanceRepository _repository;

  Future<Result<AttendanceRecord>> call({
    required String sessionId,
    required int major,
    required int minor,
  }) {
    if (minor < 0 || minor > 65535 || major < 0 || major > 65535) {
      return Future.value(const Err(ValidationFailure('비컨 식별자가 올바르지 않아요')));
    }
    return _repository.checkInByBle(
      sessionId: sessionId,
      major: major,
      minor: minor,
    );
  }
}

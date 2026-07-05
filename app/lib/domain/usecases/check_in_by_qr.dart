import '../../core/result/result.dart';
import '../entities/attendance_record.dart';
import '../repositories/attendance_repository.dart';

/// ST-4: 회전 QR 스캔 출석 (1급 경로).
class CheckInByQr {
  const CheckInByQr(this._repository);

  final AttendanceRepository _repository;

  Future<Result<AttendanceRecord>> call({
    required String sessionId,
    required String code,
  }) {
    return _repository.checkInByQr(sessionId: sessionId, code: code);
  }
}

import '../entities/attendance_record.dart';
import '../repositories/attendance_repository.dart';

/// TE-2: 실시간 현황 (Realtime ≤3s).
class WatchLiveAttendance {
  const WatchLiveAttendance(this._repository);

  final AttendanceRepository _repository;

  Stream<List<AttendanceRecord>> call(String sessionId) =>
      _repository.watchSession(sessionId);
}

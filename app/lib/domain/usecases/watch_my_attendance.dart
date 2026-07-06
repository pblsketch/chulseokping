import '../entities/attendance_record.dart';
import '../repositories/attendance_repository.dart';

/// 학생앱: 활성 세션의 본인 출석 기록을 실시간 구독 (홈 화면 "출석됨" 표시).
class WatchMyAttendance {
  const WatchMyAttendance(this._repository);

  final AttendanceRepository _repository;

  Stream<AttendanceRecord?> call(String sessionId) =>
      _repository.watchMyRecord(sessionId);
}

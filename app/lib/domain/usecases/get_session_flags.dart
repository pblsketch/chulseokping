import '../../core/result/result.dart';
import '../entities/suspicious_flag.dart';
import '../repositories/attendance_repository.dart';

/// P0-3: 세션 의심 신호 조회 — 미확인(unreviewed) 우선 정렬.
class GetSessionFlags {
  const GetSessionFlags(this._repository);

  final AttendanceRepository _repository;

  Future<Result<List<SuspiciousFlag>>> call(String sessionId) async {
    final result = await _repository.sessionFlags(sessionId);
    return result.fold(
      (flags) => Ok(
        [...flags]..sort((a, b) {
          if (a.reviewed != b.reviewed) return a.reviewed ? 1 : -1;
          return b.createdAt.compareTo(a.createdAt);
        }),
      ),
      Err.new,
    );
  }
}

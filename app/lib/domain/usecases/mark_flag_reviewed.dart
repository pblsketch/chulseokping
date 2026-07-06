import '../../core/result/result.dart';
import '../repositories/attendance_repository.dart';

/// P0-3: 의심 신호 확인 처리 — 판단은 교사 몫, 시스템은 표시만 정리한다.
class MarkFlagReviewed {
  const MarkFlagReviewed(this._repository);

  final AttendanceRepository _repository;

  Future<Result<void>> call(String flagId) =>
      _repository.markFlagReviewed(flagId);
}

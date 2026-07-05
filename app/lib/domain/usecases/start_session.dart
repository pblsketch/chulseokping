import '../../core/error/failure.dart';
import '../../core/result/result.dart';
import '../entities/session.dart';
import '../repositories/session_repository.dart';
import '../value_objects/session_type.dart';

/// TE-1: 세션 시작. PERIOD면 교시(1~15) 필수 (PRD §3).
class StartSession {
  const StartSession(this._repository);

  final SessionRepository _repository;

  Future<Result<Session>> call({
    required String classId,
    required SessionType type,
    int? period,
    SessionMode mode = SessionMode.byod,
  }) {
    if (type == SessionType.period &&
        (period == null || period < 1 || period > 15)) {
      return Future.value(const Err(ValidationFailure('교시를 선택해 주세요 (1~15)')));
    }
    if (type == SessionType.homeroom && period != null) {
      return Future.value(const Err(ValidationFailure('조회 세션에는 교시가 없어요')));
    }
    return _repository.startSession(
      classId: classId,
      type: type,
      period: period,
      mode: mode,
    );
  }
}

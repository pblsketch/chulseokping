import '../../core/error/failure.dart';
import '../../core/result/result.dart';
import '../entities/session.dart';
import '../repositories/session_repository.dart';

/// P0-1: 수집 창 연장 (기본 +5분). 창 없는(수동 종료) 세션에는 의미 없음.
class ExtendSession {
  const ExtendSession(this._repository);

  final SessionRepository _repository;

  Future<Result<Session>> call(String sessionId, {int byMinutes = 5}) {
    if (byMinutes < 1 || byMinutes > 60) {
      return Future.value(const Err(ValidationFailure('연장은 1~60분이에요')));
    }
    return _repository.extendSession(sessionId, byMinutes: byMinutes);
  }
}

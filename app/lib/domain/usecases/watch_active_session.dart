import '../entities/session.dart';
import '../repositories/session_repository.dart';

/// 학생앱: 학급의 활성 세션을 실시간으로 구독한다 (ST-2/ST-3 진입점).
class WatchActiveSession {
  const WatchActiveSession(this._repository);

  final SessionRepository _repository;

  Stream<Session?> call(String classId) =>
      _repository.watchActiveSession(classId);
}

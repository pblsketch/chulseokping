import '../../core/result/result.dart';
import '../entities/session.dart';
import '../repositories/session_repository.dart';

/// 학생앱: 소속 학급의 활성 세션 감지 (없으면 null).
class GetActiveSession {
  const GetActiveSession(this._repository);

  final SessionRepository _repository;

  Future<Result<Session?>> call(String classId) =>
      _repository.activeSessionFor(classId);
}

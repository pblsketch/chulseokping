import '../../core/result/result.dart';
import '../entities/session.dart';
import '../value_objects/session_type.dart';

abstract interface class SessionRepository {
  Future<Result<Session>> startSession({
    required String classId,
    required SessionType type,
    int? period,
    required SessionMode mode,
  });

  Future<Result<Session>> endSession(String sessionId);

  /// 학생앱: 소속 학급의 활성 세션 감지
  Future<Result<Session?>> activeSessionFor(String classId);
}

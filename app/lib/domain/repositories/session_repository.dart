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

  /// 교사 전용: 회전 QR 표시용 TOTP secret (RLS가 교사=자기 학급으로 제한).
  /// 검증은 항상 서버가 한다 — 이 값은 표시용 코드 생성에만 쓴다.
  Future<Result<String>> classSecret(String classId);
}

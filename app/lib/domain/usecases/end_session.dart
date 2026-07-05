import '../../core/result/result.dart';
import '../entities/session.dart';
import '../repositories/session_repository.dart';

/// TE-1 / BE-5: 세션 중단 (BLE 광고·회전 QR 중지는 presentation이 후속 처리).
class EndSession {
  const EndSession(this._repository);

  final SessionRepository _repository;

  Future<Result<Session>> call(String sessionId) =>
      _repository.endSession(sessionId);
}

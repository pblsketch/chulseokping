/// 도메인 실패 타입 (ARCHITECTURE §2 core/error).
/// 예외를 레이어 밖으로 누수시키지 않는다 — data 레이어가 Exception을 Failure로 변환.
sealed class Failure {
  const Failure(this.message);

  /// 사용자 노출 가능한 한국어 메시지.
  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = '네트워크에 연결할 수 없어요']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = '로그인이 필요해요']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = '입력값이 올바르지 않아요']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = '서버 오류가 발생했어요']);
}

class BleFailure extends Failure {
  const BleFailure([super.message = '비컨을 찾을 수 없어요']);
}

/// PI-2: 보호자 동의 미확인 학생의 출결 수집은 서버가 거부한다.
class ConsentRequiredFailure extends Failure {
  const ConsentRequiredFailure([super.message = '보호자 동의 확인이 필요해요']);
}

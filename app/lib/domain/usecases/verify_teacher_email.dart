import '../../core/error/failure.dart';
import '../../core/result/result.dart';
import '../repositories/auth_repository.dart';

/// M5: 가입 확인 메일의 6자리 OTP 검증 — 성공 시 세션 발급.
class VerifyTeacherEmail {
  const VerifyTeacherEmail(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({required String email, required String token}) {
    if (!RegExp(r'^\d{6}$').hasMatch(token.trim())) {
      return Future.value(const Err(ValidationFailure('인증 코드는 숫자 6자리예요')));
    }
    return _repository.verifySignUpCode(
      email: email.trim(),
      token: token.trim(),
    );
  }
}

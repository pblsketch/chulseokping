import '../../core/error/failure.dart';
import '../../core/result/result.dart';
import '../repositories/auth_repository.dart';

/// M5: 재설정 OTP 검증 + 새 비밀번호 적용.
class ConfirmPasswordReset {
  const ConfirmPasswordReset(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({
    required String email,
    required String token,
    required String newPassword,
  }) {
    if (!RegExp(r'^\d{6}$').hasMatch(token.trim())) {
      return Future.value(const Err(ValidationFailure('인증 코드는 숫자 6자리예요')));
    }
    if (newPassword.length < 8) {
      return Future.value(const Err(ValidationFailure('비밀번호는 8자 이상이어야 해요')));
    }
    return _repository.confirmPasswordReset(
      email: email.trim(),
      token: token.trim(),
      newPassword: newPassword,
    );
  }
}

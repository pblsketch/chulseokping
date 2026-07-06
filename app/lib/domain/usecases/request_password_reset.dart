import '../../core/error/failure.dart';
import '../../core/result/result.dart';
import '../repositories/auth_repository.dart';

/// M5: 교사 비밀번호 재설정 메일(OTP) 요청.
class RequestPasswordReset {
  const RequestPasswordReset(this._repository);

  final AuthRepository _repository;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Future<Result<void>> call(String email) {
    final trimmed = email.trim();
    if (!_emailPattern.hasMatch(trimmed)) {
      return Future.value(const Err(ValidationFailure('이메일 형식이 올바르지 않아요')));
    }
    return _repository.requestPasswordReset(trimmed);
  }
}

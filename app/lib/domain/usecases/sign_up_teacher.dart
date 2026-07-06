import '../../core/error/failure.dart';
import '../../core/result/result.dart';
import '../repositories/auth_repository.dart';
import '../value_objects/sign_up_outcome.dart';

/// M5: 교사 회원가입(이메일+비밀번호). 형식 선검증, 정본은 Supabase Auth.
class SignUpTeacher {
  const SignUpTeacher(this._repository);

  final AuthRepository _repository;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Future<Result<SignUpOutcome>> call({
    required String email,
    required String password,
  }) {
    final trimmed = email.trim();
    if (!_emailPattern.hasMatch(trimmed)) {
      return Future.value(const Err(ValidationFailure('이메일 형식이 올바르지 않아요')));
    }
    if (password.length < 8) {
      return Future.value(const Err(ValidationFailure('비밀번호는 8자 이상이어야 해요')));
    }
    return _repository.signUpTeacher(email: trimmed, password: password);
  }
}

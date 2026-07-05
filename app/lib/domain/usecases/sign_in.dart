import '../../core/result/result.dart';
import '../entities/user_profile.dart';
import '../repositories/auth_repository.dart';

class SignIn {
  const SignIn(this._repository);

  final AuthRepository _repository;

  Future<Result<UserProfile>> call({
    required String email,
    required String password,
  }) {
    return _repository.signIn(email: email, password: password);
  }
}

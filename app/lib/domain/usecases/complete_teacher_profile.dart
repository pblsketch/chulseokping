import '../../core/error/failure.dart';
import '../../core/result/result.dart';
import '../entities/user_profile.dart';
import '../repositories/auth_repository.dart';

/// M5: 인증 완료된 사용자의 교사 프로필 생성 (가입 마지막 단계).
class CompleteTeacherProfile {
  const CompleteTeacherProfile(this._repository);

  final AuthRepository _repository;

  Future<Result<UserProfile>> call({required String name}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 50) {
      return Future.value(const Err(ValidationFailure('이름은 1~50자로 입력해 주세요')));
    }
    return _repository.completeTeacherProfile(name: trimmed);
  }
}

import '../../core/result/result.dart';
import '../entities/user_profile.dart';

abstract interface class AuthRepository {
  Future<Result<UserProfile>> signIn({
    required String email,
    required String password,
  });

  Future<Result<void>> signOut();

  /// 세션이 살아있으면 프로필, 없으면 null
  Future<Result<UserProfile?>> currentProfile();
}

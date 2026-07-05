import '../../core/error/failure.dart';
import '../../core/result/result.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/supabase_remote_data_source.dart';
import 'failure_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote);

  final SupabaseRemoteDataSource _remote;

  @override
  Future<Result<UserProfile>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userId = await _remote.signIn(email: email, password: password);
      final profile = await _remote.fetchProfile(userId);
      if (profile == null) {
        return const Err(AuthFailure('프로필이 아직 없어요 — 가입을 먼저 완료해 주세요'));
      }
      return Ok(profile.toUserProfile());
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _remote.signOut();
      return const Ok(null);
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }

  @override
  Future<Result<UserProfile?>> currentProfile() async {
    try {
      final userId = _remote.currentUserId;
      if (userId == null) return const Ok(null);
      final profile = await _remote.fetchProfile(userId);
      return Ok(profile?.toUserProfile());
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }
}

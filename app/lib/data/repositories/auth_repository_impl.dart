import '../../core/error/failure.dart';
import '../../core/result/result.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/value_objects/sign_up_outcome.dart';
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

  @override
  Future<Result<SignUpOutcome>> signUpTeacher({
    required String email,
    required String password,
  }) async {
    try {
      final hasSession = await _remote.signUpTeacher(
        email: email,
        password: password,
      );
      return Ok(
        hasSession
            ? SignUpOutcome.sessionReady
            : SignUpOutcome.verificationEmailSent,
      );
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }

  @override
  Future<Result<void>> verifySignUpCode({
    required String email,
    required String token,
  }) async {
    try {
      await _remote.verifySignUpOtp(email: email, token: token);
      return const Ok(null);
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }

  @override
  Future<Result<UserProfile>> completeTeacherProfile({
    required String name,
  }) async {
    try {
      final userId = _remote.currentUserId;
      if (userId == null) return const Err(AuthFailure());
      // 재시도(앱 재실행 등)에도 안전하게 — 이미 있으면 그대로 반환
      final existing = await _remote.fetchProfile(userId);
      if (existing != null) return Ok(existing.toUserProfile());

      await _remote.insertOwnProfile(
        userId: userId,
        role: 'teacher',
        name: name,
      );
      final profile = await _remote.fetchProfile(userId);
      if (profile == null) return const Err(ServerFailure('프로필 생성에 실패했어요'));
      return Ok(profile.toUserProfile());
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }

  @override
  Future<Result<void>> requestPasswordReset(String email) async {
    try {
      await _remote.requestPasswordReset(email);
      return const Ok(null);
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }

  @override
  Future<Result<void>> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      await _remote.verifyRecoveryOtp(email: email, token: token);
      await _remote.updatePassword(newPassword);
      await _remote.signOut(); // 새 비밀번호로 재로그인 유도
      return const Ok(null);
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }

  @override
  Future<Result<UserProfile>> signInWithLinkCode(String code) async {
    try {
      final credentials = await _remote.invokeCheckIn('redeem_link_code', {
        'code': code,
      });
      final userId = await _remote.signIn(
        email: credentials['email'] as String,
        password: credentials['password'] as String,
      );
      final profile = await _remote.fetchProfile(userId);
      if (profile == null) {
        return const Err(AuthFailure('학생 정보를 찾을 수 없어요 — 선생님께 문의해 주세요'));
      }
      return Ok(profile.toUserProfile());
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }
}

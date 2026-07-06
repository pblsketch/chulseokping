import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/error/failure.dart';
import '../../domain/entities/user_profile.dart';

/// 로그인 세션 상태. null = 미로그인.
class AuthController extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final result = await ref.read(authRepositoryProvider).currentProfile();
    return result.fold((profile) => profile, (_) => null);
  }

  /// 성공 시 null, 실패 시 Failure 반환(폼에 표시).
  Future<Failure?> signIn(String email, String password) async {
    state = const AsyncLoading();
    final result = await ref
        .read(signInProvider)
        .call(email: email, password: password);
    return result.fold(
      (profile) {
        state = AsyncData(profile);
        return null;
      },
      (failure) {
        state = const AsyncData(null);
        return failure;
      },
    );
  }

  /// 학생 연결 코드 로그인 (M5). 성공 시 null, 실패 시 Failure 반환.
  Future<Failure?> signInWithLinkCode(String code) async {
    state = const AsyncLoading();
    final result = await ref.read(signInWithLinkCodeProvider).call(code);
    return result.fold(
      (profile) {
        state = AsyncData(profile);
        return null;
      },
      (failure) {
        state = const AsyncData(null);
        return failure;
      },
    );
  }

  /// 회원가입 완료 등 외부에서 확정된 프로필 반영 — 라우터 redirect 트리거.
  void setProfile(UserProfile profile) {
    state = AsyncData(profile);
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserProfile?>(AuthController.new);

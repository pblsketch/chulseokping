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

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserProfile?>(AuthController.new);

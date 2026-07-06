import '../../core/result/result.dart';
import '../entities/user_profile.dart';
import '../value_objects/sign_up_outcome.dart';

abstract interface class AuthRepository {
  Future<Result<UserProfile>> signIn({
    required String email,
    required String password,
  });

  Future<Result<void>> signOut();

  /// 세션이 살아있으면 프로필, 없으면 null
  Future<Result<UserProfile?>> currentProfile();

  // ── M5 계정·온보딩 ──

  /// 교사 회원가입 — 이메일 인증 설정에 따라 세션 즉시 발급 또는 확인 메일 발송
  Future<Result<SignUpOutcome>> signUpTeacher({
    required String email,
    required String password,
  });

  /// 가입 확인 메일의 6자리 OTP 검증 — 성공 시 세션 발급
  Future<Result<void>> verifySignUpCode({
    required String email,
    required String token,
  });

  /// 인증 완료된 사용자의 교사 프로필 생성(이미 있으면 그대로 반환)
  Future<Result<UserProfile>> completeTeacherProfile({required String name});

  /// 교사 비밀번호 재설정 메일(OTP) 요청
  Future<Result<void>> requestPasswordReset(String email);

  /// 재설정 OTP 검증 + 새 비밀번호 적용. 완료 후 로그아웃(재로그인 유도).
  Future<Result<void>> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
  });

  /// 학생 연결 코드 교환 → 내부 자격으로 로그인 (redeem_link_code 경유)
  Future<Result<UserProfile>> signInWithLinkCode(String code);
}

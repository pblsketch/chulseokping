import '../../core/error/failure.dart';
import '../../core/result/result.dart';
import '../entities/user_profile.dart';
import '../repositories/auth_repository.dart';

/// M5: 학생 연결 코드 로그인 — 서버 계약과 동일한 정규화/형식(32자 알파벳 × 12자).
/// 정본 판정은 redeem_link_code Edge Function.
class SignInWithLinkCode {
  const SignInWithLinkCode(this._repository);

  final AuthRepository _repository;

  static const codeLength = 12;
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// 대문자화 + 공백/하이픈 제거 (표시형 ABCD-EFGH-JKLM 입력 허용)
  static String normalize(String input) =>
      input.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');

  static bool isValidFormat(String code) =>
      code.length == codeLength && code.split('').every(_alphabet.contains);

  Future<Result<UserProfile>> call(String rawCode) {
    final code = normalize(rawCode);
    if (!isValidFormat(code)) {
      return Future.value(
        const Err(ValidationFailure('연결 코드는 12자리예요 — 선생님께 받은 코드를 확인해 주세요')),
      );
    }
    return _repository.signInWithLinkCode(code);
  }
}

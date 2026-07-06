/// 재발급된 학생 연결 코드 — 학생용 "비밀번호 재설정"에 해당 (담임만 발급 가능).
class IssuedLinkCode {
  const IssuedLinkCode({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;
}

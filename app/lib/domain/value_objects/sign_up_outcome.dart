/// 회원가입 직후 상태 — 서버 이메일 인증 설정에 따라 갈린다.
enum SignUpOutcome {
  /// 세션 즉시 발급됨 (이메일 인증 비활성 환경) — 바로 프로필 생성으로
  sessionReady,

  /// 확인 메일 발송됨 — OTP 입력 단계 필요
  verificationEmailSent,
}

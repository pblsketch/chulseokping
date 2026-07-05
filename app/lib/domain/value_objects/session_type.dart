/// 세션 유형 (PRD §3 — v1 출결 단위 = 세션).
enum SessionType {
  /// 담임 조회 출석 (하루 1회) → NEIS 일 단위 출결
  homeroom('HOMEROOM'),

  /// 교과 교시별 (1~N교시) → NEIS 결과(교시 결손)
  period('PERIOD');

  const SessionType(this.wireName);

  final String wireName;

  static SessionType fromWire(String value) =>
      SessionType.values.firstWhere((t) => t.wireName == value);
}

/// 세션 모드 (PRD §3 기본 모드 규칙).
enum SessionMode {
  kiosk('KIOSK'),
  byod('BYOD');

  const SessionMode(this.wireName);

  final String wireName;

  static SessionMode fromWire(String value) =>
      SessionMode.values.firstWhere((m) => m.wireName == value);
}

/// 세션 수명주기 (BE-5).
enum SessionStatus {
  active('ACTIVE'),
  ended('ENDED');

  const SessionStatus(this.wireName);

  final String wireName;

  static SessionStatus fromWire(String value) =>
      SessionStatus.values.firstWhere((s) => s.wireName == value);
}

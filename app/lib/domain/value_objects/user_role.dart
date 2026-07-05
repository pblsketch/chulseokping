/// 인증 사용자 역할 (ARCHITECTURE §5 — 키오스크는 역할이 아니라 기기 모드).
enum UserRole {
  teacher('teacher'),
  student('student');

  const UserRole(this.wireName);

  final String wireName;

  static UserRole fromWire(String value) =>
      UserRole.values.firstWhere((r) => r.wireName == value);
}

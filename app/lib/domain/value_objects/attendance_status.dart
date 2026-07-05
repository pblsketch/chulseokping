/// 출결 상태 5종 (ATTENDANCE_POLICY §1·§10.1 — 2축 모델의 상태축).
enum AttendanceStatus {
  /// 정상 출석
  present('출석'),

  /// 등교시각까지 출석하지 않음(등교는 함)
  late_('지각'),

  /// 등교~하교 사이에 하교
  earlyLeave('조퇴'),

  /// 결과(缺課): 수업시간 일부/전부 불참(등교는 함) — 교시(PERIOD) 단위
  classAbsent('결과'),

  /// 당일 미등교(일 단위)
  absent('결석');

  const AttendanceStatus(this.label);

  /// 한글 라벨 — UI는 색만으로 상태를 전달하지 않고 항상 이 라벨을 병기한다.
  final String label;

  /// 서버(attendance_status enum) 값
  String get wireName => switch (this) {
    AttendanceStatus.present => 'present',
    AttendanceStatus.late_ => 'late',
    AttendanceStatus.earlyLeave => 'early_leave',
    AttendanceStatus.classAbsent => 'class_absent',
    AttendanceStatus.absent => 'absent',
  };

  static AttendanceStatus fromWire(String value) =>
      AttendanceStatus.values.firstWhere((s) => s.wireName == value);
}

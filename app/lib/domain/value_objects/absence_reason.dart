/// 사유 4종 (ATTENDANCE_POLICY §2 — 2축 모델의 사유축, 상태와 직교).
/// 핵심: NEIS 칸 집계 대상은 {질병, 미인정, 기타}뿐이며, 출석인정은 NEIS상 출석 처리.
enum AbsenceReason {
  /// 출석인정 — NEIS 결석/지각/조퇴/결과 칸에 미집계(출석으로 처리)
  recognized('출석인정'),

  /// 질병·부상
  sick('질병'),

  /// 정당한 사유 없음/고의(무단) — 입시 감점·징계 사유
  unrecognized('미인정'),

  /// 그 밖의 부득이한 사유
  other('기타');

  const AbsenceReason(this.label);

  final String label;

  /// NEIS 예외 내보내기 포함 대상인가 (ATTENDANCE_POLICY §10.2 — 사유 기준)
  bool get countsForNeis => this != AbsenceReason.recognized;

  String get wireName => name;

  static AbsenceReason fromWire(String value) =>
      AbsenceReason.values.firstWhere((r) => r.wireName == value);
}

/// 출석인정 세부 코드 (ATTENDANCE_POLICY §3·§10.1).
enum RecognizedCode {
  familyEvent('경조사'),
  infectiousDisease('법정감염병'),
  naturalDisaster('천재지변'),

  /// 교외체험학습 — 출석인정이면서 학생부 미기재(§5) → NEIS 내보내기 제외
  fieldTrip('교외체험학습'),
  schoolViolence('학폭피해'),
  otherRecognized('기타인정');

  const RecognizedCode(this.label);

  final String label;

  String get wireName => switch (this) {
    RecognizedCode.familyEvent => 'family_event',
    RecognizedCode.infectiousDisease => 'infectious_disease',
    RecognizedCode.naturalDisaster => 'natural_disaster',
    RecognizedCode.fieldTrip => 'field_trip',
    RecognizedCode.schoolViolence => 'school_violence',
    RecognizedCode.otherRecognized => 'other_recognized',
  };

  static RecognizedCode fromWire(String value) =>
      RecognizedCode.values.firstWhere((c) => c.wireName == value);
}

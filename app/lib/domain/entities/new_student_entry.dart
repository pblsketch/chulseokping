/// 학생 일괄 생성 입력 한 행 (M5 하이브리드 모델 — 교사 일괄 생성 경로).
class NewStudentEntry {
  const NewStudentEntry({
    required this.name,
    required this.studentNumber,
    this.guardianConsented = false,
  });

  final String name;
  final String studentNumber;

  /// 보호자 동의를 이미 받았는지 — true면 서버가 생성과 동시에 consents 기록(PI-2)
  final bool guardianConsented;
}

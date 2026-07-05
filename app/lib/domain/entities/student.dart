/// 학생 — PII 최소화: 식별자·이름·학번만 (PRD §8 데이터 최소화).
class Student {
  const Student({
    required this.id,
    required this.name,
    required this.studentNumber,
    this.consentConfirmed = false,
  });

  final String id;
  final String name;
  final String studentNumber;

  /// 보호자 동의 확인 여부 — 서버가 정본(클라이언트 표시용)
  final bool consentConfirmed;
}

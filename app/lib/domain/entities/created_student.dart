/// create_students 결과 한 행 — 부분 성공을 허용하므로 실패 행도 그대로 보고한다.
class CreatedStudent {
  const CreatedStudent({
    required this.ok,
    required this.name,
    required this.studentNumber,
    this.studentId,
    this.linkCode,
    this.error,
  });

  final bool ok;
  final String name;
  final String studentNumber;
  final String? studentId;

  /// 학생 기기 연결용 코드 — 이 응답에서만 평문 노출(서버는 해시만 보관)
  final String? linkCode;
  final String? error;
}

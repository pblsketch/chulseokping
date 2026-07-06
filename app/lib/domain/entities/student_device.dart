/// 교사 승인 UI용 — 담당 학생의 등록 기기 (P0-2).
class StudentDevice {
  const StudentDevice({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.platform,
    required this.status,
    required this.registeredAt,
    this.model,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String platform;
  final String? model;

  /// active | pending | revoked
  final String status;
  final DateTime registeredAt;

  bool get isPending => status == 'pending';
}

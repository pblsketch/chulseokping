/// 보호자 동의 기록 (PI-2). 미존재 시 서버가 출결 수집을 거부한다.
class ConsentRecord {
  const ConsentRecord({
    required this.id,
    required this.studentId,
    required this.policyVersion,
    required this.consentedAt,
    this.guardianConfirmedBy,
  });

  final String id;
  final String studentId;
  final String policyVersion;
  final DateTime consentedAt;

  /// 보호자 동의를 확인한 교사 id
  final String? guardianConfirmedBy;
}

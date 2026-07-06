/// 부정 의심 신호 (로그-온리 — 차단 없음, 교사 판단 자료).
/// evidence는 최소 정보만 — 좌표·raw RSSI 금지 (PRD §7).
class SuspiciousFlag {
  const SuspiciousFlag({
    required this.id,
    required this.flagType,
    required this.reviewed,
    required this.createdAt,
    this.studentId,
    this.evidence,
  });

  final String id;
  final String flagType;
  final String? studentId;
  final Map<String, dynamic>? evidence;
  final bool reviewed;
  final DateTime createdAt;

  /// 교사 표시용 한국어 라벨 — 미지의 타입은 원문 노출(신형 서버 대비)
  String get label => switch (flagType) {
    'duplicate_method' => '중복 방식 재시도',
    'UNBOUND_DEVICE_CHECKIN' => '미등록 기기 출석',
    'MULTI_ACCOUNT_SAME_DEVICE' => '한 기기 복수 계정',
    'RAPID_DEVICE_REBIND' => '잦은 기기 변경',
    'SHARED_DEVICE' => '공유 기기 (형제 등 정상일 수 있음)',
    'CHECKIN_HEADCOUNT_GAP' => '자동 출석 수 ≠ 실제 인원',
    _ => flagType,
  };
}

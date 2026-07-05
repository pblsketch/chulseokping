/// 키오스크 기기. beacon minor는 저장하지 않는다(서버 시간 파생 — 회전).
class KioskDevice {
  const KioskDevice({
    required this.id,
    required this.classId,
    required this.teacherId,
    required this.beaconMajor,
    this.revoked = false,
    this.lastSeenAt,
  });

  final String id;
  final String classId;
  final String teacherId;
  final int beaconMajor;
  final bool revoked;
  final DateTime? lastSeenAt;
}

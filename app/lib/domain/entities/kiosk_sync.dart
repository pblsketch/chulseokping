import '../value_objects/session_type.dart';

/// 키오스크가 광고/표시에 쓰는 세션 요약.
class KioskSession {
  const KioskSession({required this.id, required this.type, this.period});

  final String id;
  final SessionType type;
  final int? period;

  String get label => type == SessionType.homeroom ? '조회' : '$period교시';
}

/// kiosk_sync 결과 — 키오스크의 단일 상태 원천.
/// secret들은 표시(회전 QR)·광고(회전 minor) 계산용이며 검증은 항상 서버가 한다.
class KioskSyncState {
  const KioskSyncState({
    required this.deviceId,
    required this.classId,
    required this.className,
    required this.beaconMajor,
    required this.beaconSecret,
    this.qrSecret,
    this.activeSession,
  });

  final String deviceId;
  final String classId;
  final String className;
  final int beaconMajor;
  final String beaconSecret;
  final String? qrSecret;
  final KioskSession? activeSession;
}

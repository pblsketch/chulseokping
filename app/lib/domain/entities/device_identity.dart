/// 이 기기의 바인딩 신원 — 서버 발급 uuid + 현재 상태 (P0-2).
/// uuid는 보안저장소(Keychain/Keystore)에만 보관한다.
class DeviceIdentity {
  const DeviceIdentity({required this.uuid, required this.status});

  final String uuid;

  /// active | pending | revoked — pending이면 교사 승인 대기(출석은 로그-온리로 계속 가능)
  final String status;

  bool get isPending => status == 'pending';
}

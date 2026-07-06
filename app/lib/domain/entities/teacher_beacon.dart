/// BYOD 세션 중 교사 기기가 비컨 역할을 하기 위한 신원 (kiosk_devices 행 재사용).
/// 키오스크가 없는 교실에서는 교사 태블릿/폰이 유일한 비컨 송신원이다.
class TeacherBeaconIdentity {
  const TeacherBeaconIdentity({
    required this.deviceToken,
    required this.beaconMajor,
    required this.beaconSecret,
  });

  final String deviceToken;
  final int beaconMajor;

  /// 회전 minor(TOTP) 파생용 hex secret — 서버 check_in_ble가 동일 secret으로 검증.
  final String beaconSecret;
}

/// BLE 비컨 광고 추상화 (KO-3) — 구현은 data 레이어(beacon_broadcast).
/// 광고 내용 = 고정 UUID + class별 major + 회전 minor. 그 외 어떤 정보도 싣지 않는다.
abstract interface class BeaconAdvertiser {
  /// 지원 안 되는 플랫폼/기기면 false — 키오스크는 QR/PIN만으로 동작한다.
  Future<bool> isSupported();

  Future<void> start({required int major, required int minor});

  Future<void> stop();
}

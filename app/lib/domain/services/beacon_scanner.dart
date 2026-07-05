/// 감지된 비컨 신호 — 근접 식별자(major/회전 minor)와 신호세기만.
/// 좌표는 어떤 형태로도 수집하지 않는다 (PI-3). RSSI raw는 서버로 보내지 않는다(PRD §8).
class BeaconSighting {
  const BeaconSighting({
    required this.major,
    required this.minor,
    required this.rssi,
  });

  final int major;
  final int minor;
  final int rssi;
}

/// BLE 비컨 감지 추상화 (ST-2/ST-3) — 구현은 data 레이어(dchs_flutter_beacon).
/// iPhone은 CoreLocation iBeacon ranging(포그라운드), Android는 동일 플러그인 ranging.
abstract interface class BeaconScanner {
  /// 권한·블루투스 상태 확인(온보딩 ST-6 최소). 거부/미지원이면 false → QR 폴백.
  Future<bool> prepare();

  /// 제품 고정 UUID region의 ranging 스트림.
  Stream<List<BeaconSighting>> ranging();
}

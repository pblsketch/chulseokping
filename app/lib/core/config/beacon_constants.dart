/// BLE iBeacon 계약 (ARCHITECTURE §4/§6-A).
/// UUID는 제품 고정 — 학생앱은 이 UUID의 region만 감지한다(M3).
/// class 구분 = major, 신선도 = 회전 minor(TOTP). 좌표는 어디에도 없다.
abstract final class BeaconConstants {
  static const String proximityUuid = '4CC5A2E8-1E5F-4F3A-8C4D-2B9A0E7D6F31';

  /// 광고 식별자 (Android beacon_broadcast identifier)
  static const String advertiserId = 'kr.chulseokping.kiosk';

  /// Android 광고 레이아웃 — 반드시 iBeacon.
  /// 수신측(dchs_flutter_beacon)은 iBeacon만 파싱하므로 beacon_broadcast 기본값
  /// (AltBeacon)으로 광고하면 같은 방에서도 영원히 감지되지 않는다 (2026-07-06 실기 회귀).
  static const String iBeaconLayout =
      'm:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24';

  /// iBeacon manufacturer ID (Apple, 0x004C) — 레이아웃과 세트로 필요.
  static const int iBeaconManufacturerId = 0x004c;
}

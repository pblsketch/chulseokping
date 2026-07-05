/// BLE iBeacon 계약 (ARCHITECTURE §4/§6-A).
/// UUID는 제품 고정 — 학생앱은 이 UUID의 region만 감지한다(M3).
/// class 구분 = major, 신선도 = 회전 minor(TOTP). 좌표는 어디에도 없다.
abstract final class BeaconConstants {
  static const String proximityUuid = '4CC5A2E8-1E5F-4F3A-8C4D-2B9A0E7D6F31';

  /// 광고 식별자 (Android beacon_broadcast identifier)
  static const String advertiserId = 'kr.chulseokping.kiosk';
}

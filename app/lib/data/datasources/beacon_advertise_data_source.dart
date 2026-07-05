import 'dart:io';

import 'package:beacon_broadcast/beacon_broadcast.dart';

import '../../core/config/beacon_constants.dart';
import '../../domain/services/beacon_advertiser.dart';

/// KO-3: iBeacon 광고 — 고정 UUID + major + 회전 minor.
/// 실기기 전용(에뮬레이터/데스크톱은 isSupported=false → QR/PIN 폴백).
class BeaconAdvertiseDataSource implements BeaconAdvertiser {
  BeaconAdvertiseDataSource({BeaconBroadcast? broadcast})
    : _broadcast = broadcast ?? BeaconBroadcast();

  final BeaconBroadcast _broadcast;
  bool _advertising = false;

  @override
  Future<bool> isSupported() async {
    if (!Platform.isAndroid) return false; // 키오스크 광고는 Android 태블릿만 (PRD)
    try {
      final status = await _broadcast.checkTransmissionSupported();
      return status == BeaconStatus.supported;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> start({required int major, required int minor}) async {
    // minor 회전 = stop 후 재광고 (beacon_broadcast는 파라미터 변경 API가 없다)
    await stop();
    _broadcast
        .setUUID(BeaconConstants.proximityUuid)
        .setMajorId(major)
        .setMinorId(minor)
        .setIdentifier(BeaconConstants.advertiserId)
        .setLayout(BeaconBroadcast.ALTBEACON_LAYOUT);
    await _broadcast.start();
    _advertising = true;
  }

  @override
  Future<void> stop() async {
    if (!_advertising) return;
    await _broadcast.stop();
    _advertising = false;
  }
}

import 'package:dchs_flutter_beacon/dchs_flutter_beacon.dart';

import '../../core/config/beacon_constants.dart';
import '../../domain/services/beacon_scanner.dart';

/// ST-2/ST-3: iBeacon 감지 — dchs_flutter_beacon (iPhone=CoreLocation ranging 필수).
/// `flutter_blue_plus`로는 iPhone iBeacon 감지가 불가하다 (AGENTS.md §3 — 사용 금지).
class BeaconScanDataSource implements BeaconScanner {
  @override
  Future<bool> prepare() async {
    try {
      // 권한 요청 + 블루투스/위치 서비스 상태 확인까지 수행한다.
      await flutterBeacon.initializeAndCheckScanning;
      return true;
    } catch (_) {
      return false; // 권한 거부/미지원 → QR 폴백 (ST-4가 1급 경로)
    }
  }

  @override
  Stream<List<BeaconSighting>> ranging() {
    final region = Region(
      identifier: BeaconConstants.advertiserId,
      proximityUUID: BeaconConstants.proximityUuid,
    );
    return flutterBeacon
        .ranging(<Region>[region])
        .map(
          (result) => result.beacons
              .map(
                (beacon) => BeaconSighting(
                  major: beacon.major,
                  minor: beacon.minor,
                  rssi: beacon.rssi,
                ),
              )
              .toList(),
        );
  }
}

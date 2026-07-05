import 'package:chulseokping_app/domain/services/beacon_scanner.dart';
import 'package:chulseokping_app/domain/usecases/beacon_sighting_stabilizer.dart';
import 'package:flutter_test/flutter_test.dart';

BeaconSighting s(int major, int minor, int rssi) =>
    BeaconSighting(major: major, minor: minor, rssi: rssi);

void main() {
  test('임계 미달 RSSI는 무시된다', () {
    final stabilizer = BeaconSightingStabilizer(
      rssiThreshold: -75,
      requiredConsecutive: 3,
    );
    for (var i = 0; i < 10; i++) {
      expect(stabilizer.add([s(101, i, -90)]), isNull);
    }
  });

  test('같은 major 3회 연속(회전 minor여도) → 안정 감지, 최신 minor 반환', () {
    final stabilizer = BeaconSightingStabilizer(requiredConsecutive: 3);
    expect(stabilizer.add([s(101, 1000, -60)]), isNull);
    expect(stabilizer.add([s(101, 2000, -62)]), isNull);
    final stable = stabilizer.add([s(101, 3000, -61)]);
    expect(stable, isNotNull);
    expect(stable!.major, 101);
    expect(stable.minor, 3000, reason: '최신 minor를 반환해야 서버 TOTP 창을 통과한다');
  });

  test('중간에 신호가 끊기면 streak 리셋', () {
    final stabilizer = BeaconSightingStabilizer(requiredConsecutive: 3);
    stabilizer.add([s(101, 1, -60)]);
    stabilizer.add([s(101, 2, -60)]);
    stabilizer.add(const []); // 미감지 → 리셋
    stabilizer.add([s(101, 3, -60)]);
    expect(stabilizer.add([s(101, 4, -60)]), isNull, reason: '리셋 후 2회째');
    expect(stabilizer.add([s(101, 5, -60)]), isNotNull);
  });

  test('여러 비컨이 잡히면 같은 major 중 가장 강한 신호 기준', () {
    final stabilizer = BeaconSightingStabilizer(requiredConsecutive: 1);
    final stable = stabilizer.add([
      s(101, 1, -70),
      s(101, 2, -55), // 더 강함
      s(202, 3, -80), // 임계 미달
    ]);
    expect(stable!.minor, 2);
  });

  test('reset()으로 streak 초기화', () {
    final stabilizer = BeaconSightingStabilizer(requiredConsecutive: 2);
    stabilizer.add([s(101, 1, -60)]);
    stabilizer.reset();
    expect(stabilizer.add([s(101, 2, -60)]), isNull);
  });
}

import 'package:beacon_broadcast/beacon_broadcast.dart';
import 'package:chulseokping_app/core/config/beacon_constants.dart';
import 'package:chulseokping_app/data/datasources/beacon_advertise_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBroadcast extends Mock implements BeaconBroadcast {}

void main() {
  late MockBroadcast broadcast;
  late BeaconAdvertiseDataSource dataSource;

  setUp(() {
    broadcast = MockBroadcast();
    dataSource = BeaconAdvertiseDataSource(broadcast: broadcast);
    when(() => broadcast.setUUID(any())).thenReturn(broadcast);
    when(() => broadcast.setMajorId(any())).thenReturn(broadcast);
    when(() => broadcast.setMinorId(any())).thenReturn(broadcast);
    when(() => broadcast.setIdentifier(any())).thenReturn(broadcast);
    when(() => broadcast.setLayout(any())).thenReturn(broadcast);
    when(() => broadcast.setManufacturerId(any())).thenReturn(broadcast);
    when(() => broadcast.start()).thenAnswer((_) async {});
    when(() => broadcast.stop()).thenAnswer((_) async {});
  });

  test('광고는 반드시 iBeacon 레이아웃 + Apple manufacturer ID로 시작한다 '
      '(수신측 dchs_flutter_beacon은 iBeacon만 파싱 — 2026-07-06 실기 회귀)', () async {
    await dataSource.start(major: 101, minor: 4242);

    verify(() => broadcast.setLayout(BeaconConstants.iBeaconLayout)).called(1);
    verify(
      () => broadcast.setManufacturerId(BeaconConstants.iBeaconManufacturerId),
    ).called(1);
    verify(() => broadcast.setUUID(BeaconConstants.proximityUuid)).called(1);
    verify(() => broadcast.setMajorId(101)).called(1);
    verify(() => broadcast.setMinorId(4242)).called(1);
    verify(() => broadcast.start()).called(1);
  });

  test('iBeacon 레이아웃 상수는 AltBeacon과 다르다 (기본값 회귀 방지)', () {
    expect(
      BeaconConstants.iBeaconLayout,
      isNot(BeaconBroadcast.ALTBEACON_LAYOUT),
    );
    expect(BeaconConstants.iBeaconLayout, contains('m:2-3=0215'));
    expect(BeaconConstants.iBeaconManufacturerId, 0x004c);
  });

  test('minor 회전: start 재호출 시 이전 광고를 stop 후 재시작한다', () async {
    await dataSource.start(major: 101, minor: 1);
    await dataSource.start(major: 101, minor: 2);

    verify(() => broadcast.stop()).called(1); // 첫 start는 미광고 상태라 skip
    verify(() => broadcast.setMinorId(2)).called(1);
    verify(() => broadcast.start()).called(2);
  });
}

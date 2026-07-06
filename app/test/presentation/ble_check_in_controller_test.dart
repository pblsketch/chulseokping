import 'dart:async';

import 'package:chulseokping_app/core/di/providers.dart';
import 'package:chulseokping_app/core/error/failure.dart';
import 'package:chulseokping_app/core/result/result.dart';
import 'package:chulseokping_app/domain/entities/attendance_record.dart';
import 'package:chulseokping_app/domain/repositories/attendance_repository.dart';
import 'package:chulseokping_app/domain/services/beacon_scanner.dart';
import 'package:chulseokping_app/domain/value_objects/attendance_status.dart';
import 'package:chulseokping_app/domain/value_objects/check_in_mode.dart';
import 'package:chulseokping_app/presentation/student/ble_check_in_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}

class FakeScanner implements BeaconScanner {
  FakeScanner({this.prepared = true});

  final bool prepared;
  final StreamController<List<BeaconSighting>> controller =
      StreamController.broadcast();

  @override
  Future<bool> prepare() async => prepared;

  @override
  Stream<List<BeaconSighting>> ranging() => controller.stream;
}

BeaconSighting strong(int minor) =>
    BeaconSighting(major: 101, minor: minor, rssi: -60);

final record = AttendanceRecord(
  id: 'r1',
  studentId: 'st1',
  classId: 'c1',
  sessionId: 's1',
  method: CheckInMode.ble,
  status: AttendanceStatus.present,
  checkInTime: DateTime(2026, 7, 5, 9),
);

void main() {
  late MockAttendanceRepository repository;
  late FakeScanner scanner;

  ProviderContainer container({required bool isAndroid}) {
    final c = ProviderContainer(
      overrides: [
        attendanceRepositoryProvider.overrideWithValue(repository),
        beaconScannerProvider.overrideWithValue(scanner),
        isAndroidProvider.overrideWithValue(isAndroid),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    repository = MockAttendanceRepository();
    scanner = FakeScanner();
    when(
      () => repository.checkInByBle(
        sessionId: any(named: 'sessionId'),
        major: any(named: 'major'),
        minor: any(named: 'minor'),
      ),
    ).thenAnswer((_) async => Ok(record));
  });

  Future<void> pump(
    ProviderContainer c,
    List<List<BeaconSighting>> frames,
  ) async {
    for (final frame in frames) {
      scanner.controller.add(frame);
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('Android: 3회 연속 안정 감지 → 자동 제출 → BleSuccess', () async {
    final c = container(isAndroid: true);
    final notifier = c.read(bleCheckInControllerProvider('s1').notifier);
    // autoDispose 방지: 상태 구독 유지
    final sub = c.listen(bleCheckInControllerProvider('s1'), (_, _) {});
    addTearDown(sub.close);

    await notifier.start();
    expect(c.read(bleCheckInControllerProvider('s1')), isA<BleScanning>());

    await pump(c, [
      [strong(1000)],
      [strong(2000)],
      [strong(3000)],
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(c.read(bleCheckInControllerProvider('s1')), isA<BleSuccess>());
    verify(
      () => repository.checkInByBle(sessionId: 's1', major: 101, minor: 3000),
    ).called(1);
  });

  test('iOS: 안정 감지 → BleDetected(원탭 대기) → confirm() → 제출', () async {
    final c = container(isAndroid: false);
    final notifier = c.read(bleCheckInControllerProvider('s1').notifier);
    final sub = c.listen(bleCheckInControllerProvider('s1'), (_, _) {});
    addTearDown(sub.close);

    await notifier.start();
    await pump(c, [
      [strong(1)],
      [strong(2)],
      [strong(3)],
    ]);

    expect(
      c.read(bleCheckInControllerProvider('s1')),
      isA<BleDetected>(),
      reason: 'iPhone은 자동 제출하지 않는다 (ST-3 원탭)',
    );
    verifyNever(
      () => repository.checkInByBle(
        sessionId: any(named: 'sessionId'),
        major: any(named: 'major'),
        minor: any(named: 'minor'),
      ),
    );

    await notifier.confirm();
    expect(c.read(bleCheckInControllerProvider('s1')), isA<BleSuccess>());
  });

  test('권한 거부 → BleUnavailable (QR 폴백 안내)', () async {
    scanner = FakeScanner(prepared: false);
    final c = container(isAndroid: true);
    final notifier = c.read(bleCheckInControllerProvider('s1').notifier);
    final sub = c.listen(bleCheckInControllerProvider('s1'), (_, _) {});
    addTearDown(sub.close);

    await notifier.start();
    expect(c.read(bleCheckInControllerProvider('s1')), isA<BleUnavailable>());
  });

  test('약한 신호만 계속이면 제출하지 않는다', () async {
    final c = container(isAndroid: true);
    final notifier = c.read(bleCheckInControllerProvider('s1').notifier);
    final sub = c.listen(bleCheckInControllerProvider('s1'), (_, _) {});
    addTearDown(sub.close);

    await notifier.start();
    await pump(c, [
      for (var i = 0; i < 10; i++)
        [BeaconSighting(major: 101, minor: i, rssi: -95)],
    ]);

    expect(c.read(bleCheckInControllerProvider('s1')), isA<BleScanning>());
    verifyNever(
      () => repository.checkInByBle(
        sessionId: any(named: 'sessionId'),
        major: any(named: 'major'),
        minor: any(named: 'minor'),
      ),
    );
  });

  test('제한 시간 내 미감지 → BleNotFound (무한 스피너 방지), retry로 재스캔', () async {
    final original = BleCheckInController.scanTimeout;
    BleCheckInController.scanTimeout = const Duration(milliseconds: 30);
    addTearDown(() => BleCheckInController.scanTimeout = original);

    final c = container(isAndroid: true);
    final notifier = c.read(bleCheckInControllerProvider('s1').notifier);
    final sub = c.listen(bleCheckInControllerProvider('s1'), (_, _) {});
    addTearDown(sub.close);

    await notifier.start();
    expect(c.read(bleCheckInControllerProvider('s1')), isA<BleScanning>());

    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(
      c.read(bleCheckInControllerProvider('s1')),
      isA<BleNotFound>(),
      reason: '비컨 없음(교사 미광고 등)에서 무한 "감지 중"이면 안 된다',
    );

    await notifier.retry();
    expect(c.read(bleCheckInControllerProvider('s1')), isA<BleScanning>());
  });

  test('감지 성공 시 타임아웃이 상태를 덮어쓰지 않는다', () async {
    final original = BleCheckInController.scanTimeout;
    BleCheckInController.scanTimeout = const Duration(milliseconds: 30);
    addTearDown(() => BleCheckInController.scanTimeout = original);

    final c = container(isAndroid: true);
    final notifier = c.read(bleCheckInControllerProvider('s1').notifier);
    final sub = c.listen(bleCheckInControllerProvider('s1'), (_, _) {});
    addTearDown(sub.close);

    await notifier.start();
    await pump(c, [
      [strong(1)],
      [strong(2)],
      [strong(3)],
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(bleCheckInControllerProvider('s1')), isA<BleSuccess>());

    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(c.read(bleCheckInControllerProvider('s1')), isA<BleSuccess>());
  });

  test('서버 거부(동의 없음) → BleFailed 메시지', () async {
    when(
      () => repository.checkInByBle(
        sessionId: any(named: 'sessionId'),
        major: any(named: 'major'),
        minor: any(named: 'minor'),
      ),
    ).thenAnswer((_) async => const Err(ConsentRequiredFailure()));

    final c = container(isAndroid: true);
    final notifier = c.read(bleCheckInControllerProvider('s1').notifier);
    final sub = c.listen(bleCheckInControllerProvider('s1'), (_, _) {});
    addTearDown(sub.close);

    await notifier.start();
    await pump(c, [
      [strong(1)],
      [strong(2)],
      [strong(3)],
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(c.read(bleCheckInControllerProvider('s1')), isA<BleFailed>());
  });
}

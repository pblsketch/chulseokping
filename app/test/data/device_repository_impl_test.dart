import 'package:chulseokping_app/data/repositories/attendance_repository_impl.dart';
import 'package:chulseokping_app/data/repositories/device_repository_impl.dart';
import 'package:chulseokping_app/data/datasources/supabase_remote_data_source.dart';
import 'package:chulseokping_app/domain/entities/device_identity.dart';
import 'package:chulseokping_app/domain/services/device_identity_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements SupabaseRemoteDataSource {}

/// 보안저장소 대역 — 계약(load/save)만 검증, 실제 Keychain/Keystore는 실기기 영역.
class FakeDeviceStore implements DeviceIdentityStore {
  DeviceIdentity? identity;

  @override
  Future<DeviceIdentity?> load() async => identity;

  @override
  Future<void> save(DeviceIdentity value) async => identity = value;
}

void main() {
  late MockRemote remote;
  late FakeDeviceStore store;
  late DeviceRepositoryImpl repository;

  const record = {
    'id': 'log-1',
    'student_id': 'st1',
    'class_id': 'c1',
    'session_id': 's1',
    'method': 'QR',
    'status': 'present',
    'check_in_time': '2026-07-06T09:00:00Z',
  };

  setUp(() {
    remote = MockRemote();
    store = FakeDeviceStore();
    repository = DeviceRepositoryImpl(remote, store, 'android');
  });

  group('ensureRegistered', () {
    test('최초(보관 uuid 없음): platform만 전송 → 발급 uuid 보관', () async {
      when(() => remote.invokeCheckIn(any(), any())).thenAnswer(
        (_) async => {'device_uuid': 'uuid-new', 'status': 'active'},
      );

      final result = await repository.ensureRegistered();
      expect(result.valueOrNull?.uuid, 'uuid-new');
      expect(store.identity?.uuid, 'uuid-new', reason: '보안저장소에 보관');

      final body =
          verify(
                () => remote.invokeCheckIn('register_device', captureAny()),
              ).captured.single
              as Map<String, dynamic>;
      expect(body['platform'], 'android');
      expect(body.containsKey('device_uuid'), isFalse);
    });

    test('보관 uuid 있음: 멱등 재확인 전송 + 서버 상태로 갱신', () async {
      store.identity = const DeviceIdentity(uuid: 'uuid-old', status: 'active');
      when(() => remote.invokeCheckIn(any(), any())).thenAnswer(
        (_) async => {'device_uuid': 'uuid-old', 'status': 'pending'},
      );

      final result = await repository.ensureRegistered();
      expect(result.valueOrNull?.isPending, isTrue);
      expect(store.identity?.status, 'pending', reason: '서버 상태가 정본');

      final body =
          verify(
                () => remote.invokeCheckIn('register_device', captureAny()),
              ).captured.single
              as Map<String, dynamic>;
      expect(body['device_uuid'], 'uuid-old');
    });
  });

  group('체크인 payload (P0-2)', () {
    test('보관 uuid가 있으면 QR 체크인에 device_uuid 동봉', () async {
      store.identity = const DeviceIdentity(uuid: 'uuid-1', status: 'active');
      when(
        () => remote.invokeCheckIn(any(), any()),
      ).thenAnswer((_) async => {'created': true, 'record': record});

      final attendance = AttendanceRepositoryImpl(remote, deviceStore: store);
      await attendance.checkInByQr(sessionId: 's1', code: '123456');

      final body =
          verify(
                () => remote.invokeCheckIn('check_in_qr', captureAny()),
              ).captured.single
              as Map<String, dynamic>;
      expect(body['device_uuid'], 'uuid-1');
    });

    test('보관 uuid가 없으면 미동봉 (서버는 무플래그 통과)', () async {
      when(
        () => remote.invokeCheckIn(any(), any()),
      ).thenAnswer((_) async => {'created': true, 'record': record});

      final attendance = AttendanceRepositoryImpl(remote, deviceStore: store);
      await attendance.checkInByBle(sessionId: 's1', major: 101, minor: 7);

      final body =
          verify(
                () => remote.invokeCheckIn('check_in_ble', captureAny()),
              ).captured.single
              as Map<String, dynamic>;
      expect(body.containsKey('device_uuid'), isFalse);
    });
  });
}

import 'package:chulseokping_app/core/error/failure.dart';
import 'package:chulseokping_app/core/result/result.dart';
import 'package:chulseokping_app/domain/entities/teacher_beacon.dart';
import 'package:chulseokping_app/domain/repositories/kiosk_repository.dart';
import 'package:chulseokping_app/domain/services/teacher_beacon_store.dart';
import 'package:chulseokping_app/domain/usecases/ensure_teacher_beacon.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockKioskRepository extends Mock implements KioskRepository {}

class MockStore extends Mock implements TeacherBeaconStore {}

final stored = TeacherBeaconIdentity(
  deviceToken: 'kp-stored',
  beaconMajor: 101,
  beaconSecret: 'aa' * 20,
);

final issued = TeacherBeaconIdentity(
  deviceToken: 'kp-new',
  beaconMajor: 202,
  beaconSecret: 'bb' * 20,
);

void main() {
  late MockKioskRepository repository;
  late MockStore store;
  late EnsureTeacherBeacon usecase;

  setUpAll(() => registerFallbackValue(stored));

  setUp(() {
    repository = MockKioskRepository();
    store = MockStore();
    usecase = EnsureTeacherBeacon(repository, store);
    when(() => store.write(any(), any())).thenAnswer((_) async {});
    when(() => store.clear(any())).thenAnswer((_) async {});
  });

  test('로컬 신원이 서버에 살아 있으면 재사용 (재발급 없음)', () async {
    when(() => store.read('c1')).thenAnswer((_) async => stored);
    when(
      () => repository.isBeaconDeviceActive('kp-stored'),
    ).thenAnswer((_) async => const Ok(true));

    final result = await usecase('c1');

    expect(result.valueOrNull?.deviceToken, 'kp-stored');
    verifyNever(() => repository.issueClassBeacon(any()));
  });

  test('서버에서 사라진 신원(DB 리셋/회수)은 지우고 재발급', () async {
    when(() => store.read('c1')).thenAnswer((_) async => stored);
    when(
      () => repository.isBeaconDeviceActive('kp-stored'),
    ).thenAnswer((_) async => const Ok(false));
    when(
      () => repository.issueClassBeacon('c1'),
    ).thenAnswer((_) async => Ok(issued));

    final result = await usecase('c1');

    expect(result.valueOrNull?.deviceToken, 'kp-new');
    verify(() => store.clear('c1')).called(1);
    verify(() => store.write('c1', issued)).called(1);
  });

  test('로컬 신원 없음(최초) → 발급 후 저장', () async {
    when(() => store.read('c1')).thenAnswer((_) async => null);
    when(
      () => repository.issueClassBeacon('c1'),
    ).thenAnswer((_) async => Ok(issued));

    final result = await usecase('c1');

    expect(result.valueOrNull?.beaconMajor, 202);
    verify(() => store.write('c1', issued)).called(1);
  });

  test('존재 확인 중 네트워크 오류면 재발급하지 않고 실패 전달 (중복 등록 방지)', () async {
    when(() => store.read('c1')).thenAnswer((_) async => stored);
    when(
      () => repository.isBeaconDeviceActive('kp-stored'),
    ).thenAnswer((_) async => const Err(NetworkFailure()));

    final result = await usecase('c1');

    expect(result.failureOrNull, isA<NetworkFailure>());
    verifyNever(() => repository.issueClassBeacon(any()));
    verifyNever(() => store.clear(any()));
  });
}

import 'package:chulseokping_app/core/error/failure.dart';
import 'package:chulseokping_app/core/result/result.dart';
import 'package:chulseokping_app/domain/entities/attendance_record.dart';
import 'package:chulseokping_app/domain/repositories/attendance_repository.dart';
import 'package:chulseokping_app/domain/usecases/confirm_headcount.dart';
import 'package:chulseokping_app/domain/value_objects/attendance_status.dart';
import 'package:chulseokping_app/domain/value_objects/check_in_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}

AttendanceRecord _record(CheckInMode method, {AttendanceStatus? status}) =>
    AttendanceRecord(
      id: 'log-${method.wireName}',
      studentId: 'st1',
      classId: 'c1',
      sessionId: 's1',
      method: method,
      status: status ?? AttendanceStatus.present,
      checkInTime: DateTime.utc(2026, 7, 6, 9),
    );

void main() {
  late MockAttendanceRepository repository;

  setUp(() {
    repository = MockAttendanceRepository();
  });

  test('autoCount: QR/BLE만 집계 — PIN/MANUAL/LIST 제외', () {
    final records = [
      _record(CheckInMode.qr),
      _record(CheckInMode.ble),
      _record(CheckInMode.pin),
      _record(CheckInMode.manual),
      _record(CheckInMode.list),
    ];
    expect(ConfirmHeadcount.autoCount(records), 2);
    expect(ConfirmHeadcount.autoCount(const []), 0);
  });

  test('P0-1 회귀 가드: 자동 지각(late)은 사유 미확정(null)으로 생성 가능해야 한다', () {
    // 서버가 만드는 late+사유null 레코드를 앱이 파싱할 때 assert로 죽으면 안 된다
    final lateRecord = _record(
      CheckInMode.ble,
      status: AttendanceStatus.late_,
    );
    expect(lateRecord.status, AttendanceStatus.late_);
    expect(lateRecord.reason, isNull);
  });

  test('관측 인원 범위 검증 (0~999)', () async {
    final usecase = ConfirmHeadcount(repository);
    for (final observed in [-1, 1000]) {
      final result = await usecase(
        sessionId: 's1',
        matches: false,
        observedCount: observed,
      );
      expect(result.failureOrNull, isA<ValidationFailure>());
    }
    verifyZeroInteractions(repository);
  });

  test('유효 입력은 위임', () async {
    when(
      () => repository.confirmHeadcount(
        sessionId: any(named: 'sessionId'),
        matches: any(named: 'matches'),
        observedCount: any(named: 'observedCount'),
      ),
    ).thenAnswer((_) async => const Ok(null));

    final result = await ConfirmHeadcount(
      repository,
    ).call(sessionId: 's1', matches: false, observedCount: 20);
    expect(result.isOk, isTrue);
    verify(
      () => repository.confirmHeadcount(
        sessionId: 's1',
        matches: false,
        observedCount: 20,
      ),
    ).called(1);
  });
}

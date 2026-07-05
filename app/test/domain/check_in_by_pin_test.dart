import 'package:chulseokping_app/core/error/failure.dart';
import 'package:chulseokping_app/core/result/result.dart';
import 'package:chulseokping_app/domain/entities/attendance_record.dart';
import 'package:chulseokping_app/domain/repositories/kiosk_repository.dart';
import 'package:chulseokping_app/domain/usecases/check_in_by_pin.dart';
import 'package:chulseokping_app/domain/value_objects/attendance_status.dart';
import 'package:chulseokping_app/domain/value_objects/check_in_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockKioskRepository extends Mock implements KioskRepository {}

void main() {
  late MockKioskRepository repository;
  late CheckInByPin usecase;

  setUp(() {
    repository = MockKioskRepository();
    usecase = CheckInByPin(repository);
  });

  test('학번 공백 → ValidationFailure, 저장소 호출 없음', () async {
    final result = await usecase(
      deviceToken: 'kp-x',
      sessionId: 's1',
      studentNumber: '  ',
      pin: '1234',
    );
    expect(result.failureOrNull, isA<ValidationFailure>());
    verifyZeroInteractions(repository);
  });

  test('PIN 4자리 미만 → ValidationFailure', () async {
    final result = await usecase(
      deviceToken: 'kp-x',
      sessionId: 's1',
      studentNumber: '10101',
      pin: '12',
    );
    expect(result.failureOrNull, isA<ValidationFailure>());
    verifyZeroInteractions(repository);
  });

  test('정상 입력은 trim해서 위임', () async {
    final record = AttendanceRecord(
      id: 'r1',
      studentId: 'st1',
      classId: 'c1',
      sessionId: 's1',
      method: CheckInMode.pin,
      status: AttendanceStatus.present,
      checkInTime: DateTime(2026, 7, 5, 9),
    );
    when(
      () => repository.checkInByPin(
        deviceToken: any(named: 'deviceToken'),
        sessionId: any(named: 'sessionId'),
        studentNumber: any(named: 'studentNumber'),
        pin: any(named: 'pin'),
      ),
    ).thenAnswer((_) async => Ok(record));

    final result = await usecase(
      deviceToken: 'kp-x',
      sessionId: 's1',
      studentNumber: ' 10101 ',
      pin: '1234',
    );
    expect(result.isOk, isTrue);
    verify(
      () => repository.checkInByPin(
        deviceToken: 'kp-x',
        sessionId: 's1',
        studentNumber: '10101',
        pin: '1234',
      ),
    ).called(1);
  });
}

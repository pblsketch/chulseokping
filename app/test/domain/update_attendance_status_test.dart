import 'package:chulseokping_app/core/error/failure.dart';
import 'package:chulseokping_app/core/result/result.dart';
import 'package:chulseokping_app/domain/entities/attendance_record.dart';
import 'package:chulseokping_app/domain/repositories/attendance_repository.dart';
import 'package:chulseokping_app/domain/usecases/start_session.dart';
import 'package:chulseokping_app/domain/usecases/update_attendance_status.dart';
import 'package:chulseokping_app/domain/repositories/session_repository.dart';
import 'package:chulseokping_app/domain/value_objects/absence_reason.dart';
import 'package:chulseokping_app/domain/value_objects/attendance_status.dart';
import 'package:chulseokping_app/domain/value_objects/check_in_mode.dart';
import 'package:chulseokping_app/domain/value_objects/session_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}

class MockSessionRepository extends Mock implements SessionRepository {}

final dummyRecord = AttendanceRecord(
  id: 'r1',
  studentId: 'st1',
  classId: 'c1',
  sessionId: 's1',
  method: CheckInMode.manual,
  status: AttendanceStatus.absent,
  reason: AbsenceReason.other,
  checkInTime: DateTime(2026, 7, 5, 9),
);

void main() {
  late MockAttendanceRepository repository;
  late UpdateAttendanceStatus usecase;

  setUpAll(() {
    registerFallbackValue(AttendanceStatus.present);
    registerFallbackValue(AbsenceReason.sick);
    registerFallbackValue(RecognizedCode.fieldTrip);
  });

  setUp(() {
    repository = MockAttendanceRepository();
    usecase = UpdateAttendanceStatus(repository);
  });

  test('recordId 있으면 updateStatus 경로', () async {
    when(
      () => repository.updateStatus(
        recordId: any(named: 'recordId'),
        status: any(named: 'status'),
        reason: any(named: 'reason'),
        reasonCode: any(named: 'reasonCode'),
        reasonDetail: any(named: 'reasonDetail'),
      ),
    ).thenAnswer((_) async => Ok(dummyRecord));

    final result = await usecase(
      recordId: 'r1',
      status: AttendanceStatus.late_,
      reason: AbsenceReason.sick,
    );
    expect(result.isOk, isTrue);
    verifyNever(
      () => repository.markManual(
        sessionId: any(named: 'sessionId'),
        studentId: any(named: 'studentId'),
        status: any(named: 'status'),
        reason: any(named: 'reason'),
        reasonCode: any(named: 'reasonCode'),
        reasonDetail: any(named: 'reasonDetail'),
      ),
    );
  });

  test('recordId 없고 세션+학생 있으면 markManual 경로', () async {
    when(
      () => repository.markManual(
        sessionId: any(named: 'sessionId'),
        studentId: any(named: 'studentId'),
        status: any(named: 'status'),
        reason: any(named: 'reason'),
        reasonCode: any(named: 'reasonCode'),
        reasonDetail: any(named: 'reasonDetail'),
      ),
    ).thenAnswer((_) async => Ok(dummyRecord));

    final result = await usecase(
      sessionId: 's1',
      studentId: 'st1',
      status: AttendanceStatus.absent,
      reason: AbsenceReason.unrecognized,
    );
    expect(result.isOk, isTrue);
  });

  test('2축 위반은 저장소 호출 없이 ValidationFailure', () async {
    final presentWithReason = await usecase(
      recordId: 'r1',
      status: AttendanceStatus.present,
      reason: AbsenceReason.sick,
    );
    expect(presentWithReason.failureOrNull, isA<ValidationFailure>());

    final absentNoReason = await usecase(
      recordId: 'r1',
      status: AttendanceStatus.absent,
    );
    expect(absentNoReason.failureOrNull, isA<ValidationFailure>());

    final codeWithoutRecognized = await usecase(
      recordId: 'r1',
      status: AttendanceStatus.absent,
      reason: AbsenceReason.sick,
      reasonCode: RecognizedCode.fieldTrip,
    );
    expect(codeWithoutRecognized.failureOrNull, isA<ValidationFailure>());

    verifyZeroInteractions(repository);
  });

  group('StartSession 검증', () {
    test('PERIOD인데 교시 없으면 ValidationFailure', () async {
      final sessionRepository = MockSessionRepository();
      final startSession = StartSession(sessionRepository);
      final result = await startSession(
        classId: 'c1',
        type: SessionType.period,
      );
      expect(result.failureOrNull, isA<ValidationFailure>());
      verifyZeroInteractions(sessionRepository);
    });
  });
}

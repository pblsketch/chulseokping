import 'package:chulseokping_app/core/error/failure.dart';
import 'package:chulseokping_app/data/datasources/supabase_remote_data_source.dart';
import 'package:chulseokping_app/data/repositories/attendance_repository_impl.dart';
import 'package:chulseokping_app/domain/value_objects/attendance_status.dart';
import 'package:chulseokping_app/domain/value_objects/check_in_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockRemote extends Mock implements SupabaseRemoteDataSource {}

Map<String, dynamic> recordJson() => {
  'id': 'r1',
  'student_id': 'st1',
  'class_id': 'c1',
  'session_id': 's1',
  'method': 'QR',
  'status': 'present',
  'check_in_time': '2026-07-05T09:00:00Z',
};

void main() {
  late MockRemote remote;
  late AttendanceRepositoryImpl repository;

  setUp(() {
    remote = MockRemote();
    repository = AttendanceRepositoryImpl(remote);
  });

  test('checkInByQr: EF 응답 record → entity', () async {
    when(
      () => remote.invokeCheckIn('check_in_qr', any()),
    ).thenAnswer((_) async => {'created': true, 'record': recordJson()});
    final result = await repository.checkInByQr(
      sessionId: 's1',
      code: '123456',
    );
    expect(result.isOk, isTrue);
    expect(result.valueOrNull!.method, CheckInMode.qr);
    verify(
      () => remote.invokeCheckIn('check_in_qr', {
        'session_id': 's1',
        'code': '123456',
      }),
    ).called(1);
  });

  test('checkInByQr: 403 consent_required → ConsentRequiredFailure', () async {
    when(() => remote.invokeCheckIn(any(), any())).thenThrow(
      FunctionException(status: 403, details: {'error': 'consent_required'}),
    );
    final result = await repository.checkInByQr(
      sessionId: 's1',
      code: '123456',
    );
    expect(result.failureOrNull, isA<ConsentRequiredFailure>());
  });

  test('checkInByQr: 422 만료 → ValidationFailure(다시 스캔 안내)', () async {
    when(() => remote.invokeCheckIn(any(), any())).thenThrow(
      FunctionException(status: 422, details: {'error': 'code_expired'}),
    );
    final result = await repository.checkInByQr(
      sessionId: 's1',
      code: '000000',
    );
    final failure = result.failureOrNull;
    expect(failure, isA<ValidationFailure>());
    expect(failure!.message, contains('다시 스캔'));
  });

  test('updateStatus: wire 값으로 update_attendance 호출', () async {
    when(() => remote.invokeCheckIn('update_attendance', any())).thenAnswer(
      (_) async => {
        'created': false,
        'record': {...recordJson(), 'status': 'late', 'reason': 'sick'},
      },
    );
    final result = await repository.updateStatus(
      recordId: 'r1',
      status: AttendanceStatus.late_,
      reason: null,
    );
    expect(result.isOk, isTrue);
    verify(
      () => remote.invokeCheckIn('update_attendance', {
        'record_id': 'r1',
        'status': 'late',
        'reason': null,
        'reason_code': null,
        'reason_detail': null,
      }),
    ).called(1);
  });
}

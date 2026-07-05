import 'package:chulseokping_app/data/models/attendance_record_dto.dart';
import 'package:chulseokping_app/data/models/session_dto.dart';
import 'package:chulseokping_app/domain/value_objects/absence_reason.dart';
import 'package:chulseokping_app/domain/value_objects/attendance_status.dart';
import 'package:chulseokping_app/domain/value_objects/check_in_mode.dart';
import 'package:chulseokping_app/domain/value_objects/session_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AttendanceRecordDto: 서버 JSON → entity 매핑', () {
    final dto = AttendanceRecordDto.fromJson({
      'id': 'r1',
      'student_id': 'st1',
      'class_id': 'c1',
      'session_id': 's1',
      'method': 'QR',
      'status': 'late',
      'reason': 'sick',
      'reason_code': null,
      'reason_detail': '병원 진료',
      'document_submitted': true,
      'neis_excluded': false,
      'kiosk_device_id': null,
      'check_in_time': '2026-07-05T09:00:00Z',
      'updated_at': '2026-07-05T10:00:00Z',
      'updated_by': 't1',
    });
    final entity = dto.toEntity();
    expect(entity.method, CheckInMode.qr);
    expect(entity.status, AttendanceStatus.late_);
    expect(entity.reason, AbsenceReason.sick);
    expect(entity.documentSubmitted, isTrue);
    expect(entity.updatedBy, 't1');
  });

  test(
    'AttendanceRecordDto: 교외체험학습 — recognized + field_trip + neisExcluded',
    () {
      final dto = AttendanceRecordDto.fromJson({
        'id': 'r2',
        'student_id': 'st1',
        'class_id': 'c1',
        'session_id': 's1',
        'method': 'MANUAL',
        'status': 'absent',
        'reason': 'recognized',
        'reason_code': 'field_trip',
        'neis_excluded': true,
        'check_in_time': '2026-07-05T09:00:00Z',
      });
      final entity = dto.toEntity();
      expect(entity.reason, AbsenceReason.recognized);
      expect(entity.reasonCode, RecognizedCode.fieldTrip);
      expect(entity.neisExcluded, isTrue);
    },
  );

  test('SessionDto: 서버 JSON → entity 매핑 (PERIOD + 교시)', () {
    final dto = SessionDto.fromJson({
      'id': 's1',
      'class_id': 'c1',
      'teacher_id': 't1',
      'type': 'PERIOD',
      'period': 3,
      'date': '2026-07-05',
      'mode': 'KIOSK',
      'status': 'ACTIVE',
      'started_at': '2026-07-05T11:00:00Z',
      'ended_at': null,
    });
    final entity = dto.toEntity();
    expect(entity.type, SessionType.period);
    expect(entity.period, 3);
    expect(entity.mode, SessionMode.kiosk);
    expect(entity.status, SessionStatus.active);
  });
}

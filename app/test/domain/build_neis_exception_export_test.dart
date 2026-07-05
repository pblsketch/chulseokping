import 'package:chulseokping_app/domain/entities/attendance_record.dart';
import 'package:chulseokping_app/domain/entities/session.dart';
import 'package:chulseokping_app/domain/entities/student.dart';
import 'package:chulseokping_app/domain/usecases/build_neis_exception_export.dart';
import 'package:chulseokping_app/domain/value_objects/absence_reason.dart';
import 'package:chulseokping_app/domain/value_objects/attendance_status.dart';
import 'package:chulseokping_app/domain/value_objects/check_in_mode.dart';
import 'package:chulseokping_app/domain/value_objects/session_type.dart';
import 'package:flutter_test/flutter_test.dart';

// 회귀 가드 (ATTENDANCE_POLICY §10.4): 나이스 내보내기는 "사유 기준"이다.
void main() {
  const usecase = BuildNeisExceptionExport();

  final homeroom = Session(
    id: 's-home',
    classId: 'c1',
    teacherId: 't1',
    type: SessionType.homeroom,
    date: DateTime(2026, 7, 1),
    mode: SessionMode.kiosk,
    status: SessionStatus.ended,
    startedAt: DateTime(2026, 7, 1, 8, 30),
  );
  final period3 = Session(
    id: 's-p3',
    classId: 'c1',
    teacherId: 't1',
    type: SessionType.period,
    period: 3,
    date: DateTime(2026, 7, 1),
    mode: SessionMode.byod,
    status: SessionStatus.ended,
    startedAt: DateTime(2026, 7, 1, 11, 0),
  );
  final sessions = {homeroom.id: homeroom, period3.id: period3};
  final students = {
    'st1': const Student(id: 'st1', name: '더미학생일', studentNumber: '10101'),
    'st2': const Student(id: 'st2', name: '더미학생이', studentNumber: '10102'),
  };

  AttendanceRecord record({
    required String id,
    required String studentId,
    required String sessionId,
    required AttendanceStatus status,
    AbsenceReason? reason,
    RecognizedCode? reasonCode,
    bool neisExcluded = false,
  }) {
    return AttendanceRecord(
      id: id,
      studentId: studentId,
      classId: 'c1',
      sessionId: sessionId,
      method: CheckInMode.manual,
      status: status,
      reason: reason,
      reasonCode: reasonCode,
      neisExcluded: neisExcluded,
      checkInTime: DateTime(2026, 7, 1, 9),
    );
  }

  test('사유∈{질병,미인정,기타}인 결석/지각/결과만 포함되고 행수가 일치한다', () {
    final rows = usecase(
      records: [
        record(
          id: 'r1',
          studentId: 'st1',
          sessionId: 's-home',
          status: AttendanceStatus.absent,
          reason: AbsenceReason.sick,
        ),
        record(
          id: 'r2',
          studentId: 'st2',
          sessionId: 's-home',
          status: AttendanceStatus.late_,
          reason: AbsenceReason.unrecognized,
        ),
        record(
          id: 'r3',
          studentId: 'st1',
          sessionId: 's-p3',
          status: AttendanceStatus.classAbsent,
          reason: AbsenceReason.other,
        ),
        record(
          id: 'r4',
          studentId: 'st2',
          sessionId: 's-p3',
          status: AttendanceStatus.present,
        ),
      ],
      sessionsById: sessions,
      studentsById: students,
    );

    expect(rows, hasLength(3), reason: 'PRESENT 제외, 집계 대상 3건 = 3행');
    expect(rows.map((r) => r.statusLabel), containsAll(['결석', '지각', '결과']));
  });

  test('사유=출석인정은 내보내기에 포함되지 않는다 (§10.4 가드 1)', () {
    final rows = usecase(
      records: [
        record(
          id: 'r1',
          studentId: 'st1',
          sessionId: 's-home',
          status: AttendanceStatus.absent,
          reason: AbsenceReason.recognized,
          reasonCode: RecognizedCode.familyEvent,
        ),
      ],
      sessionsById: sessions,
      studentsById: students,
    );
    expect(rows, isEmpty, reason: '경조사 결석은 NEIS상 출석 처리 — 0행');
  });

  test('교외체험학습(neisExcluded)은 내보내기에서 제외된다 (§10.4 가드 2)', () {
    final rows = usecase(
      records: [
        record(
          id: 'r1',
          studentId: 'st1',
          sessionId: 's-home',
          status: AttendanceStatus.absent,
          reason: AbsenceReason.recognized,
          reasonCode: RecognizedCode.fieldTrip,
          neisExcluded: true,
        ),
      ],
      sessionsById: sessions,
      studentsById: students,
    );
    expect(rows, isEmpty);
  });

  test('정렬: 교시는 숫자 기준 — 2교시가 10교시보다 앞', () {
    final period2 = Session(
      id: 's-p2',
      classId: 'c1',
      teacherId: 't1',
      type: SessionType.period,
      period: 2,
      date: DateTime(2026, 7, 1),
      mode: SessionMode.byod,
      status: SessionStatus.ended,
      startedAt: DateTime(2026, 7, 1, 10, 0),
    );
    final period10 = Session(
      id: 's-p10',
      classId: 'c1',
      teacherId: 't1',
      type: SessionType.period,
      period: 10,
      date: DateTime(2026, 7, 1),
      mode: SessionMode.byod,
      status: SessionStatus.ended,
      startedAt: DateTime(2026, 7, 1, 17, 0),
    );
    final rows = usecase(
      records: [
        record(
          id: 'r1',
          studentId: 'st1',
          sessionId: 's-p10',
          status: AttendanceStatus.classAbsent,
          reason: AbsenceReason.sick,
        ),
        record(
          id: 'r2',
          studentId: 'st1',
          sessionId: 's-p2',
          status: AttendanceStatus.classAbsent,
          reason: AbsenceReason.sick,
        ),
      ],
      sessionsById: {period2.id: period2, period10.id: period10},
      studentsById: students,
    );
    expect(rows.map((r) => r.periodLabel).toList(), ['2교시', '10교시']);
  });

  test('교시 라벨: 조회=일과, 교시 세션=N교시', () {
    final rows = usecase(
      records: [
        record(
          id: 'r1',
          studentId: 'st1',
          sessionId: 's-home',
          status: AttendanceStatus.absent,
          reason: AbsenceReason.sick,
        ),
        record(
          id: 'r2',
          studentId: 'st1',
          sessionId: 's-p3',
          status: AttendanceStatus.classAbsent,
          reason: AbsenceReason.sick,
        ),
      ],
      sessionsById: sessions,
      studentsById: students,
    );
    expect(rows.map((r) => r.periodLabel), containsAll(['일과', '3교시']));
  });
}

import 'package:chulseokping_app/domain/entities/attendance_record.dart';
import 'package:chulseokping_app/domain/entities/session.dart';
import 'package:chulseokping_app/domain/entities/student.dart';
import 'package:chulseokping_app/domain/value_objects/absence_reason.dart';
import 'package:chulseokping_app/domain/value_objects/attendance_status.dart';
import 'package:chulseokping_app/domain/value_objects/check_in_mode.dart';
import 'package:chulseokping_app/domain/value_objects/session_type.dart';
import 'package:chulseokping_app/presentation/teacher/ledger_model.dart';
import 'package:flutter_test/flutter_test.dart';

Session session(String id, SessionType type, {int? period, int day = 1}) =>
    Session(
      id: id,
      classId: 'c1',
      teacherId: 't1',
      type: type,
      period: period,
      date: DateTime(2026, 7, day),
      mode: SessionMode.byod,
      status: SessionStatus.ended,
      startedAt: DateTime(2026, 7, day, 9),
    );

AttendanceRecord record(String id, String studentId, String sessionId) =>
    AttendanceRecord(
      id: id,
      studentId: studentId,
      classId: 'c1',
      sessionId: sessionId,
      method: CheckInMode.manual,
      status: AttendanceStatus.absent,
      reason: AbsenceReason.sick,
      checkInTime: DateTime(2026, 7, 1, 9),
    );

void main() {
  final sessions = {
    'home-d2': session('home-d2', SessionType.homeroom, day: 2),
    'p3-d1': session('p3-d1', SessionType.period, period: 3, day: 1),
    'p1-d1': session('p1-d1', SessionType.period, period: 1, day: 1),
  };
  const students = {
    'st1': Student(id: 'st1', name: '가학생', studentNumber: '10101'),
    'st2': Student(id: 'st2', name: '나학생', studentNumber: '10102'),
  };

  test('정렬: 날짜 → 교시(조회=0) → 학번', () {
    final rows = buildLedgerRows(
      records: [
        record('r1', 'st1', 'home-d2'),
        record('r2', 'st2', 'p3-d1'),
        record('r3', 'st1', 'p1-d1'),
      ],
      sessionsById: sessions,
      studentsById: students,
    );
    expect(rows.map((r) => r.record.id).toList(), ['r3', 'r2', 'r1']);
    expect(rows.first.periodLabel, '1교시');
    expect(rows.last.periodLabel, '일과');
  });

  test('typeFilter: 조회만 / 교시만', () {
    final records = [
      record('r1', 'st1', 'home-d2'),
      record('r2', 'st1', 'p3-d1'),
    ];
    final homeroomOnly = buildLedgerRows(
      records: records,
      sessionsById: sessions,
      studentsById: students,
      typeFilter: SessionType.homeroom,
    );
    expect(homeroomOnly.single.record.id, 'r1');

    final periodOnly = buildLedgerRows(
      records: records,
      sessionsById: sessions,
      studentsById: students,
      typeFilter: SessionType.period,
    );
    expect(periodOnly.single.record.id, 'r2');
  });

  test('세션/학생 문맥이 없는 기록은 제외', () {
    final rows = buildLedgerRows(
      records: [
        record('r1', 'ghost', 'home-d2'),
        record('r2', 'st1', 'no-session'),
      ],
      sessionsById: sessions,
      studentsById: students,
    );
    expect(rows, isEmpty);
  });
}

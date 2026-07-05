import 'package:chulseokping_app/domain/entities/attendance_record.dart';
import 'package:chulseokping_app/domain/entities/student.dart';
import 'package:chulseokping_app/domain/value_objects/attendance_status.dart';
import 'package:chulseokping_app/domain/value_objects/check_in_mode.dart';
import 'package:chulseokping_app/presentation/teacher/session_roster.dart';
import 'package:flutter_test/flutter_test.dart';

AttendanceRecord record(String studentId, AttendanceStatus status) =>
    AttendanceRecord(
      id: 'r-$studentId',
      studentId: studentId,
      classId: 'c1',
      sessionId: 's1',
      method: CheckInMode.qr,
      status: status,
      checkInTime: DateTime(2026, 7, 5, 9),
    );

void main() {
  test('mergeRoster: 기록 있는 학생은 매칭, 없는 학생은 record=null, 학번순 정렬', () {
    const students = [
      Student(id: 'b', name: '나학생', studentNumber: '10102'),
      Student(id: 'a', name: '가학생', studentNumber: '10101'),
      Student(id: 'c', name: '다학생', studentNumber: '10103'),
    ];
    final rows = mergeRoster(students, [record('a', AttendanceStatus.present)]);

    expect(rows.map((r) => r.student.studentNumber).toList(), [
      '10101',
      '10102',
      '10103',
    ]);
    expect(rows[0].record?.status, AttendanceStatus.present);
    expect(rows[1].record, isNull, reason: '미출석 학생은 기록 없음');
    expect(rows[2].record, isNull);
  });

  test('mergeRoster: 명단에 없는 학생의 기록은 표시하지 않는다', () {
    const students = [Student(id: 'a', name: '가학생', studentNumber: '10101')];
    final rows = mergeRoster(students, [
      record('ghost', AttendanceStatus.present),
    ]);
    expect(rows, hasLength(1));
    expect(rows.single.record, isNull);
  });
}

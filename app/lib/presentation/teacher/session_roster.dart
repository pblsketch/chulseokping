import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/student.dart';

/// 명단 1행 = 학생 + (있으면) 출결 기록.
class SessionRosterRow {
  const SessionRosterRow({required this.student, this.record});

  final Student student;
  final AttendanceRecord? record;
}

/// 명단과 실시간 기록을 학번순으로 병합한다 (순수 함수 — 단위 테스트 대상).
List<SessionRosterRow> mergeRoster(
  List<Student> students,
  List<AttendanceRecord> records,
) {
  final byStudentId = {for (final r in records) r.studentId: r};
  final rows = students
      .map((s) => SessionRosterRow(student: s, record: byStudentId[s.id]))
      .toList();
  rows.sort(
    (a, b) => a.student.studentNumber.compareTo(b.student.studentNumber),
  );
  return rows;
}

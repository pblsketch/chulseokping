import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/student.dart';
import '../../domain/value_objects/session_type.dart';

/// 월별 일람표 1행 = 출결 기록 + 세션·학생 문맥 (TE-4).
class LedgerRow {
  const LedgerRow({
    required this.record,
    required this.session,
    required this.student,
  });

  final AttendanceRecord record;
  final Session session;
  final Student student;

  String get periodLabel =>
      session.type == SessionType.homeroom ? '일과' : '${session.period}교시';
}

/// 기록·세션·학생을 병합해 날짜→교시→학번 순으로 정렬한다 — 순수 함수.
/// [typeFilter]로 조회/교시만 필터 (null = 전체).
List<LedgerRow> buildLedgerRows({
  required List<AttendanceRecord> records,
  required Map<String, Session> sessionsById,
  required Map<String, Student> studentsById,
  SessionType? typeFilter,
}) {
  final rows = <LedgerRow>[];
  for (final record in records) {
    final session = sessionsById[record.sessionId];
    final student = studentsById[record.studentId];
    if (session == null || student == null) continue;
    if (typeFilter != null && session.type != typeFilter) continue;
    rows.add(LedgerRow(record: record, session: session, student: student));
  }
  rows.sort((a, b) {
    final byDate = a.session.date.compareTo(b.session.date);
    if (byDate != 0) return byDate;
    final byPeriod = (a.session.period ?? 0).compareTo(b.session.period ?? 0);
    if (byPeriod != 0) return byPeriod;
    return a.student.studentNumber.compareTo(b.student.studentNumber);
  });
  return rows;
}

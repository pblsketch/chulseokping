import '../entities/attendance_record.dart';
import '../entities/session.dart';
import '../entities/student.dart';
import '../value_objects/attendance_status.dart';
import '../value_objects/session_type.dart';

/// 나이스 예외 내보내기 행 (PRD §6 컬럼 계약).
/// 내부값(RSSI/minor/좌표)은 어떤 필드로도 포함하지 않는다.
class NeisExportRow {
  const NeisExportRow({
    required this.studentNumber,
    required this.studentName,
    required this.date,
    required this.periodLabel,
    required this.statusLabel,
    required this.reasonLabel,
    this.reasonDetail,
    required this.documentSubmitted,
  });

  final String studentNumber;
  final String studentName;
  final DateTime date;

  /// 조회 세션 = "일과", 교시 세션 = "N교시"
  final String periodLabel;
  final String statusLabel;

  /// 질병/미인정/기타만 (출석인정은 행 자체가 생성되지 않음)
  final String reasonLabel;
  final String? reasonDetail;
  final bool documentSubmitted;
}

/// 나이스 "예외만 내보내기" — **사유 기준** (ATTENDANCE_POLICY §10.2, PRD §6 v1.1).
///
/// 포함: 사유 ∈ {질병, 미인정, 기타}인 결석/지각/조퇴/결과.
/// 제외: PRESENT / 사유=출석인정(NEIS상 출석 처리) / 교외체험학습(neisExcluded, 학생부 미기재).
/// 정렬: 학생 → 날짜 → 교시.
class BuildNeisExceptionExport {
  const BuildNeisExceptionExport();

  List<NeisExportRow> call({
    required List<AttendanceRecord> records,
    required Map<String, Session> sessionsById,
    required Map<String, Student> studentsById,
  }) {
    // 정렬 키로 교시 번호를 함께 보관한다 — 라벨 문자열 정렬은 '10교시'<'2교시'로 뒤집힌다.
    final entries = <({NeisExportRow row, int periodOrder})>[];
    for (final record in records) {
      if (record.status == AttendanceStatus.present) continue;
      final reason = record.reason;
      if (reason == null || !reason.countsForNeis) continue; // 출석인정 제외
      if (record.neisExcluded) continue; // 교외체험학습: 학생부 미기재

      final session = sessionsById[record.sessionId];
      final student = studentsById[record.studentId];
      if (session == null || student == null) continue;

      entries.add((
        row: NeisExportRow(
          studentNumber: student.studentNumber,
          studentName: student.name,
          date: session.date,
          periodLabel: session.type == SessionType.homeroom
              ? '일과'
              : '${session.period}교시',
          statusLabel: record.status.label,
          reasonLabel: reason.label,
          reasonDetail: record.reasonDetail,
          documentSubmitted: record.documentSubmitted,
        ),
        // 조회(일과)=0으로 교시들보다 앞에 둔다
        periodOrder: session.type == SessionType.homeroom ? 0 : session.period!,
      ));
    }

    entries.sort((a, b) {
      final byStudent = a.row.studentNumber.compareTo(b.row.studentNumber);
      if (byStudent != 0) return byStudent;
      final byDate = a.row.date.compareTo(b.row.date);
      if (byDate != 0) return byDate;
      return a.periodOrder.compareTo(b.periodOrder);
    });
    return entries.map((e) => e.row).toList();
  }
}

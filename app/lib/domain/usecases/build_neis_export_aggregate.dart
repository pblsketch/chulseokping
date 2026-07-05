import 'build_neis_exception_export.dart';

/// 엑셀 시트2 집계 행 — 학생별 상태×사유 카운트 (PRD §6: 시트2=집계).
class NeisAggregateRow {
  const NeisAggregateRow({
    required this.studentNumber,
    required this.studentName,
    required this.absentSick,
    required this.absentUnrecognized,
    required this.absentOther,
    required this.late,
    required this.earlyLeave,
    required this.classAbsent,
  });

  final String studentNumber;
  final String studentName;
  final int absentSick;
  final int absentUnrecognized;
  final int absentOther;
  final int late;
  final int earlyLeave;
  final int classAbsent;
}

/// 예외 행(이미 사유 기준 필터됨)에서 학생별 집계를 만든다 — 순수 함수.
/// NEIS 표 구조(결석은 질병/미인정/기타 분리, 지각·조퇴·결과는 횟수)를 따른다.
List<NeisAggregateRow> buildNeisExportAggregate(List<NeisExportRow> rows) {
  final byStudent = <String, List<NeisExportRow>>{};
  for (final row in rows) {
    byStudent.putIfAbsent(row.studentNumber, () => []).add(row);
  }

  final result = byStudent.entries.map((entry) {
    final list = entry.value;
    int count(bool Function(NeisExportRow) test) => list.where(test).length;
    return NeisAggregateRow(
      studentNumber: entry.key,
      studentName: list.first.studentName,
      absentSick: count((r) => r.statusLabel == '결석' && r.reasonLabel == '질병'),
      absentUnrecognized: count(
        (r) => r.statusLabel == '결석' && r.reasonLabel == '미인정',
      ),
      absentOther: count((r) => r.statusLabel == '결석' && r.reasonLabel == '기타'),
      late: count((r) => r.statusLabel == '지각'),
      earlyLeave: count((r) => r.statusLabel == '조퇴'),
      classAbsent: count((r) => r.statusLabel == '결과'),
    );
  }).toList()..sort((a, b) => a.studentNumber.compareTo(b.studentNumber));
  return result;
}

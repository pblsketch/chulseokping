import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/error/failure.dart';
import '../../core/result/result.dart';
import '../../domain/repositories/export_repository.dart';
import '../../domain/usecases/build_neis_exception_export.dart';
import '../../domain/usecases/build_neis_export_aggregate.dart';
import 'failure_mapper.dart';

/// TE-5: 나이스 예외 내보내기 — 클립보드 TSV + 엑셀(시트2=집계).
/// 내부값(RSSI/minor/좌표)은 행 모델(NeisExportRow)에 존재하지 않으므로 구조적으로 미포함.
class ExportRepositoryImpl implements ExportRepository {
  ExportRepositoryImpl({Future<Directory> Function()? outputDirectory})
    : _outputDirectory = outputDirectory ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _outputDirectory;

  static const List<String> _headers = [
    '학번',
    '이름',
    '날짜',
    '교시',
    '상태',
    '사유',
    '세부사유',
    '증빙제출',
  ];

  static String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// 탭/개행이 셀 값에 섞이면 나이스 붙여넣기가 깨진다 → 공백으로 정화
  static String _sanitize(String? value) =>
      (value ?? '').replaceAll(RegExp(r'[\t\r\n]+'), ' ').trim();

  static List<String> _rowCells(NeisExportRow row) => [
    row.studentNumber,
    row.studentName,
    _formatDate(row.date),
    row.periodLabel,
    row.statusLabel,
    row.reasonLabel,
    _sanitize(row.reasonDetail),
    row.documentSubmitted ? '제출' : '',
  ];

  @override
  Future<Result<String>> toTsv(List<NeisExportRow> rows) async {
    final lines = [
      _headers.join('\t'),
      ...rows.map((row) => _rowCells(row).join('\t')),
    ];
    return Ok(lines.join('\r\n'));
  }

  @override
  Future<Result<String>> toXlsx(List<NeisExportRow> rows) async {
    try {
      final excel = Excel.createExcel();

      final listSheet = excel['예외목록'];
      listSheet.appendRow([for (final h in _headers) TextCellValue(h)]);
      for (final row in rows) {
        listSheet.appendRow([
          for (final cell in _rowCells(row)) TextCellValue(cell),
        ]);
      }

      final aggregateSheet = excel['집계'];
      aggregateSheet.appendRow([
        for (final h in [
          '학번',
          '이름',
          '결석(질병)',
          '결석(미인정)',
          '결석(기타)',
          '지각',
          '조퇴',
          '결과',
        ])
          TextCellValue(h),
      ]);
      for (final agg in buildNeisExportAggregate(rows)) {
        aggregateSheet.appendRow([
          TextCellValue(agg.studentNumber),
          TextCellValue(agg.studentName),
          IntCellValue(agg.absentSick),
          IntCellValue(agg.absentUnrecognized),
          IntCellValue(agg.absentOther),
          IntCellValue(agg.late),
          IntCellValue(agg.earlyLeave),
          IntCellValue(agg.classAbsent),
        ]);
      }

      excel.delete('Sheet1'); // 기본 빈 시트 제거

      final bytes = excel.encode();
      if (bytes == null) {
        return const Err(ServerFailure('엑셀 생성에 실패했어요'));
      }
      final directory = await _outputDirectory();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/neis_export_$stamp.xlsx');
      await file.writeAsBytes(bytes, flush: true);
      return Ok(file.path);
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }
}

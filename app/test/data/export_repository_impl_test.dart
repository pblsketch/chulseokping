import 'dart:io';

import 'package:chulseokping_app/data/repositories/export_repository_impl.dart';
import 'package:chulseokping_app/domain/usecases/build_neis_exception_export.dart';
import 'package:chulseokping_app/domain/usecases/build_neis_export_aggregate.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

NeisExportRow row({
  String number = '10101',
  String name = '더미학생일',
  String period = '일과',
  String status = '결석',
  String reason = '질병',
  String? detail,
  bool document = false,
}) {
  return NeisExportRow(
    studentNumber: number,
    studentName: name,
    date: DateTime(2026, 7, 3),
    periodLabel: period,
    statusLabel: status,
    reasonLabel: reason,
    reasonDetail: detail,
    documentSubmitted: document,
  );
}

void main() {
  late Directory tempDir;
  late ExportRepositoryImpl repository;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('neis_export_test');
    repository = ExportRepositoryImpl(outputDirectory: () async => tempDir);
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  test('TSV: 헤더 + 행, 탭 구분, 나이스 컬럼 계약 (PRD §6 v1.1)', () async {
    final result = await repository.toTsv([
      row(detail: '병원 진료', document: true),
      row(
        number: '10102',
        name: '더미학생이',
        period: '3교시',
        status: '결과',
        reason: '기타',
      ),
    ]);
    final tsv = result.valueOrNull!;
    final lines = tsv.split('\r\n');
    expect(lines, hasLength(3));
    expect(lines[0], '학번\t이름\t날짜\t교시\t상태\t사유\t세부사유\t증빙제출');
    expect(lines[1], '10101\t더미학생일\t2026-07-03\t일과\t결석\t질병\t병원 진료\t제출');
    expect(lines[2], '10102\t더미학생이\t2026-07-03\t3교시\t결과\t기타\t\t');
  });

  test('TSV: 세부사유의 탭/개행은 공백으로 정화 (붙여넣기 보호)', () async {
    final result = await repository.toTsv([row(detail: '줄바꿈\n포함\t탭도')]);
    final dataLine = result.valueOrNull!.split('\r\n')[1];
    expect(dataLine.split('\t'), hasLength(8), reason: '컬럼 수가 유지되어야 함');
    expect(dataLine, contains('줄바꿈 포함 탭도'));
  });

  test('xlsx: 파일 생성 + 시트2 집계 값 검증', () async {
    final rows = [
      row(), // 결석/질병
      row(status: '지각', reason: '미인정'),
      row(status: '지각', reason: '기타'),
      row(number: '10102', name: '더미학생이', status: '결석', reason: '미인정'),
    ];
    final result = await repository.toXlsx(rows);
    final path = result.valueOrNull!;
    expect(File(path).existsSync(), isTrue);

    final excel = Excel.decodeBytes(File(path).readAsBytesSync());
    expect(excel.sheets.keys, containsAll(['예외목록', '집계']));
    expect(excel.sheets.keys, isNot(contains('Sheet1')));

    final listSheet = excel.sheets['예외목록']!;
    expect(listSheet.maxRows, 5, reason: '헤더 1 + 데이터 4행');

    final aggregate = buildNeisExportAggregate(rows);
    expect(aggregate, hasLength(2));
    final first = aggregate.first; // 10101
    expect(first.absentSick, 1);
    expect(first.late, 2);
    expect(first.absentUnrecognized, 0);
    final second = aggregate[1]; // 10102
    expect(second.absentUnrecognized, 1);
  });
}

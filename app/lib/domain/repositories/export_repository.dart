import '../../core/result/result.dart';
import '../usecases/build_neis_exception_export.dart';

/// 내보내기 저장소 — 읽기 전용 (ARCHITECTURE §6C).
abstract interface class ExportRepository {
  /// TSV 문자열 생성(클립보드용). 행 구성은 BuildNeisExceptionExport가 정본.
  Future<Result<String>> toTsv(List<NeisExportRow> rows);

  /// xlsx 파일 생성 후 경로 반환 (시트2=집계)
  Future<Result<String>> toXlsx(List<NeisExportRow> rows);
}

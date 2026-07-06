import '../../core/result/result.dart';
import '../repositories/roster_repository.dart';

/// M6: 학급 보관 — 학년도 종료/폐급. 이력은 보존되고 목록에서만 숨겨진다.
class ArchiveClass {
  const ArchiveClass(this._repository);

  final RosterRepository _repository;

  Future<Result<void>> call(String classId) =>
      _repository.archiveClass(classId);
}

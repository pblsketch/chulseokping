import '../../core/error/failure.dart';
import '../../core/result/result.dart';
import '../repositories/roster_repository.dart';

/// M6: 학급 이름 변경.
class RenameClass {
  const RenameClass(this._repository);

  final RosterRepository _repository;

  Future<Result<void>> call({required String classId, required String name}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 30) {
      return Future.value(
        const Err(ValidationFailure('학급 이름은 1~30자로 입력해 주세요')),
      );
    }
    return _repository.renameClass(classId: classId, name: trimmed);
  }
}

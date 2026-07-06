import '../../core/error/failure.dart';
import '../../core/result/result.dart';
import '../entities/class_room.dart';
import '../repositories/roster_repository.dart';

/// M6: 학급 생성 — create_class Edge Function 경유(QR secret 동시 발급이 계약).
class CreateClass {
  const CreateClass(this._repository);

  final RosterRepository _repository;

  Future<Result<ClassRoom>> call(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 30) {
      return Future.value(
        const Err(ValidationFailure('학급 이름은 1~30자로 입력해 주세요')),
      );
    }
    return _repository.createClass(trimmed);
  }
}

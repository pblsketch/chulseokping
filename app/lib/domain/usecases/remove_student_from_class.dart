import '../../core/result/result.dart';
import '../repositories/roster_repository.dart';

/// M6: 전학/졸업 — 명단(student_classes)만 해제.
/// 출결 이력은 나이스 근거라 보존되고, 계정도 남는다(멤버십 가드가 이후 체크인을 거부).
class RemoveStudentFromClass {
  const RemoveStudentFromClass(this._repository);

  final RosterRepository _repository;

  Future<Result<void>> call({
    required String classId,
    required String studentId,
  }) => _repository.removeStudentFromClass(
    classId: classId,
    studentId: studentId,
  );
}

import '../../core/error/failure.dart';
import '../../core/result/result.dart';
import '../entities/created_student.dart';
import '../entities/new_student_entry.dart';
import '../repositories/roster_repository.dart';

/// M5: 학생 계정 일괄 생성 — 서버(create_students)와 동일한 상한.
class CreateStudents {
  const CreateStudents(this._repository);

  final RosterRepository _repository;

  static const maxPerCall = 60;

  Future<Result<List<CreatedStudent>>> call({
    required String classId,
    required List<NewStudentEntry> entries,
  }) {
    if (entries.isEmpty) {
      return Future.value(const Err(ValidationFailure('추가할 학생이 없어요')));
    }
    if (entries.length > maxPerCall) {
      return Future.value(
        const Err(ValidationFailure('한 번에 $maxPerCall명까지 추가할 수 있어요')),
      );
    }
    return _repository.createStudents(classId: classId, entries: entries);
  }
}

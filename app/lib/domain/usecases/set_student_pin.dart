import '../../core/error/failure.dart';
import '../../core/result/result.dart';
import '../repositories/roster_repository.dart';

/// TE-6: 학생 키오스크 PIN 발급. 형식 선검증(정본은 서버 set_student_pin).
class SetStudentPin {
  const SetStudentPin(this._repository);

  final RosterRepository _repository;

  Future<Result<void>> call({required String studentId, required String pin}) {
    if (!RegExp(r'^\d{4,8}$').hasMatch(pin)) {
      return Future.value(const Err(ValidationFailure('PIN은 숫자 4~8자리예요')));
    }
    return _repository.setStudentPin(studentId: studentId, pin: pin);
  }
}

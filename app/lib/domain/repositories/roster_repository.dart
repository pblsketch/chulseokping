import '../../core/result/result.dart';
import '../entities/class_room.dart';
import '../entities/student.dart';

abstract interface class RosterRepository {
  Future<Result<List<ClassRoom>>> myClasses();

  Future<Result<List<Student>>> studentsOf(String classId);

  /// TE-6: 키오스크 PIN 발급/재설정 — set_student_pin Edge Function 경유(해시만 저장).
  Future<Result<void>> setStudentPin({
    required String studentId,
    required String pin,
  });
}

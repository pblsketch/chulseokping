import '../../core/result/result.dart';
import '../entities/class_room.dart';
import '../entities/student.dart';

abstract interface class RosterRepository {
  Future<Result<List<ClassRoom>>> myClasses();

  Future<Result<List<Student>>> studentsOf(String classId);
}

import '../../core/error/failure.dart';
import '../../core/result/result.dart';
import '../../domain/entities/class_room.dart';
import '../../domain/entities/student.dart';
import '../../domain/repositories/roster_repository.dart';
import '../../domain/value_objects/user_role.dart';
import '../datasources/supabase_remote_data_source.dart';
import 'failure_mapper.dart';

class RosterRepositoryImpl implements RosterRepository {
  const RosterRepositoryImpl(this._remote);

  final SupabaseRemoteDataSource _remote;

  @override
  Future<Result<List<ClassRoom>>> myClasses() async {
    try {
      final userId = _remote.currentUserId;
      if (userId == null) return const Err(AuthFailure());
      final profile = await _remote.fetchProfile(userId);
      if (profile == null) return const Err(AuthFailure('프로필이 없어요'));

      final dtos = UserRole.fromWire(profile.role) == UserRole.teacher
          ? await _remote.classesOfTeacher(userId)
          : await _remote.classesOfStudent(userId);
      return Ok(dtos.map((dto) => dto.toEntity()).toList());
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }

  @override
  Future<Result<void>> setStudentPin({
    required String studentId,
    required String pin,
  }) async {
    try {
      await _remote.invokeCheckIn('set_student_pin', {
        'student_id': studentId,
        'pin': pin,
      });
      return const Ok(null);
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }

  @override
  Future<Result<List<Student>>> studentsOf(String classId) async {
    try {
      final profiles = await _remote.studentsOf(classId);
      final consented = await _remote.consentedStudentIds();
      final students =
          profiles
              .map(
                (p) => p.toStudent(consentConfirmed: consented.contains(p.id)),
              )
              .toList()
            ..sort((a, b) => a.studentNumber.compareTo(b.studentNumber));
      return Ok(students);
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }
}

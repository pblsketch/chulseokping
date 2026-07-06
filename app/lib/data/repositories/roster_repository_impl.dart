import '../../core/error/failure.dart';
import '../../core/result/result.dart';
import '../../domain/entities/class_room.dart';
import '../../domain/entities/created_student.dart';
import '../../domain/entities/issued_link_code.dart';
import '../../domain/entities/new_student_entry.dart';
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
  Future<Result<List<CreatedStudent>>> createStudents({
    required String classId,
    required List<NewStudentEntry> entries,
  }) async {
    try {
      final response = await _remote.invokeCheckIn('create_students', {
        'class_id': classId,
        'students': [
          for (final e in entries)
            {
              'name': e.name,
              'student_number': e.studentNumber,
              'guardian_consented': e.guardianConsented,
            },
        ],
      });
      final rows = (response['students'] as List).cast<Map<String, dynamic>>();
      return Ok([
        for (final row in rows)
          CreatedStudent(
            ok: row['ok'] as bool,
            name: row['name'] as String? ?? '',
            studentNumber: row['student_number'] as String? ?? '',
            studentId: row['student_id'] as String?,
            linkCode: row['link_code'] as String?,
            error: row['error'] as String?,
          ),
      ]);
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }

  @override
  Future<Result<IssuedLinkCode>> issueLinkCode(String studentId) async {
    try {
      final response = await _remote.invokeCheckIn('issue_link_code', {
        'student_id': studentId,
      });
      return Ok(
        IssuedLinkCode(
          code: response['link_code'] as String,
          expiresAt: DateTime.parse(response['expires_at'] as String),
        ),
      );
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

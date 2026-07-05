import '../../core/error/failure.dart';
import '../../core/result/result.dart';
import '../../domain/entities/consent_record.dart';
import '../../domain/repositories/consent_repository.dart';
import '../datasources/supabase_remote_data_source.dart';
import 'failure_mapper.dart';

class ConsentRepositoryImpl implements ConsentRepository {
  const ConsentRepositoryImpl(this._remote);

  final SupabaseRemoteDataSource _remote;

  @override
  Future<Result<ConsentRecord>> confirmGuardianConsent({
    required String studentId,
    required String policyVersion,
  }) async {
    try {
      final teacherId = _remote.currentUserId;
      if (teacherId == null) return const Err(AuthFailure());
      final dto = await _remote.insertConsent(
        studentId: studentId,
        policyVersion: policyVersion,
        teacherId: teacherId,
      );
      return Ok(dto.toEntity());
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }

  @override
  Future<Result<List<ConsentRecord>>> consentsOf(String classId) async {
    try {
      // RLS(teaches_student)가 이미 담당 학생으로 제한 → 학급 명단으로 한 번 더 필터
      final students = await _remote.studentsOf(classId);
      final studentIds = students.map((p) => p.id).toSet();
      final consents = await _remote.fetchConsents();
      return Ok(
        consents
            .where((c) => studentIds.contains(c.studentId))
            .map((c) => c.toEntity())
            .toList(),
      );
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }
}

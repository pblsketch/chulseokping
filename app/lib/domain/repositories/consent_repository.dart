import '../../core/result/result.dart';
import '../entities/consent_record.dart';

abstract interface class ConsentRepository {
  Future<Result<ConsentRecord>> confirmGuardianConsent({
    required String studentId,
    required String policyVersion,
  });

  Future<Result<List<ConsentRecord>>> consentsOf(String classId);
}

import '../../core/result/result.dart';
import '../entities/consent_record.dart';
import '../repositories/consent_repository.dart';

/// PI-2: 보호자 동의 확인 기록. 현행 처리방침 버전으로 고정.
/// ⚠ "교사 확인 갈음"의 적법성은 법률 자문 하드 게이트 대상 (PI-5) — 실운영 전 확정.
class ConfirmGuardianConsent {
  const ConfirmGuardianConsent(this._repository);

  static const String currentPolicyVersion = 'v1';

  final ConsentRepository _repository;

  Future<Result<ConsentRecord>> call(String studentId) =>
      _repository.confirmGuardianConsent(
        studentId: studentId,
        policyVersion: currentPolicyVersion,
      );
}

import '../../core/result/result.dart';
import '../entities/issued_link_code.dart';
import '../repositories/roster_repository.dart';

/// M5: 학생 연결 코드 재발급 — 기존 코드는 서버가 전부 무효화한다.
class IssueLinkCode {
  const IssueLinkCode(this._repository);

  final RosterRepository _repository;

  Future<Result<IssuedLinkCode>> call(String studentId) =>
      _repository.issueLinkCode(studentId);
}

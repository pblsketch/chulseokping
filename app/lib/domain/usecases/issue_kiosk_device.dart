import '../../core/result/result.dart';
import '../entities/kiosk_device.dart';
import '../repositories/kiosk_repository.dart';

/// KO-1: 교사가 키오스크 기기 토큰을 발급한다.
class IssueKioskDevice {
  const IssueKioskDevice(this._repository);

  final KioskRepository _repository;

  Future<Result<IssuedKioskDevice>> call(String classId) =>
      _repository.issueDevice(classId);
}

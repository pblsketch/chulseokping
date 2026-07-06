import '../../core/result/result.dart';
import '../repositories/device_repository.dart';

/// P0-2: 재바인딩 승인 — 본인 인증은 눈앞의 학생을 아는 교사(원탭).
class ApproveStudentDevice {
  const ApproveStudentDevice(this._repository);

  final DeviceRepository _repository;

  Future<Result<void>> call(String deviceId) =>
      _repository.approveDevice(deviceId);
}

/// P0-2: 기기 회수 (분실·오등록).
class RevokeStudentDevice {
  const RevokeStudentDevice(this._repository);

  final DeviceRepository _repository;

  Future<Result<void>> call(String deviceId) =>
      _repository.revokeDevice(deviceId);
}

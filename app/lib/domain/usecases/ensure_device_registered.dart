import '../../core/result/result.dart';
import '../entities/device_identity.dart';
import '../repositories/device_repository.dart';

/// P0-2: 학생 로그인 후 기기 등록/확인 — 최초 자동 active, 재바인딩은 pending.
/// 실패해도 출석은 막지 않는다(로그-온리 원칙) — 호출부는 결과를 안내용으로만 쓴다.
class EnsureDeviceRegistered {
  const EnsureDeviceRegistered(this._repository);

  final DeviceRepository _repository;

  Future<Result<DeviceIdentity>> call() => _repository.ensureRegistered();
}

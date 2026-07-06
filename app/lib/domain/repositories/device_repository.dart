import '../../core/result/result.dart';
import '../entities/device_identity.dart';
import '../entities/student_device.dart';

abstract interface class DeviceRepository {
  /// 학생 로그인 후 기기 등록/확인 — 최초는 자동 active, 재바인딩은 pending(교사 승인 대기).
  /// 서버가 uuid를 발급하고 보안저장소에 보관한다 (register_device Edge Function).
  Future<Result<DeviceIdentity>> ensureRegistered();

  /// 교사: 담당 학급 학생들의 기기 목록 (revoked 제외, 승인 UI용)
  Future<Result<List<StudentDevice>>> devicesOfClass(String classId);

  /// 교사: pending 기기 승인 — 기존 active는 자동 회수 (approve_device)
  Future<Result<void>> approveDevice(String deviceId);

  /// 교사: 기기 회수 (분실 등)
  Future<Result<void>> revokeDevice(String deviceId);
}

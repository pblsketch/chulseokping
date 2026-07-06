import '../../core/result/result.dart';
import '../entities/attendance_record.dart';
import '../entities/kiosk_device.dart';
import '../entities/kiosk_sync.dart';
import '../entities/teacher_beacon.dart';

abstract interface class KioskRepository {
  /// 교사: 기기 토큰 발급 (KO-1). 토큰·secret은 클라이언트에서 Random.secure로 생성.
  Future<Result<IssuedKioskDevice>> issueDevice(String classId);

  /// 교사: BYOD 세션용 자기 기기 비컨 등록 — kiosk_devices 행을 재사용하되
  /// secret까지 돌려받아 이 기기가 직접 광고한다 (issueDevice는 secret을 버림).
  Future<Result<TeacherBeaconIdentity>> issueClassBeacon(String classId);

  /// 등록된(미revoke) 비컨 기기인지 확인 — DB 리셋/회수 후 재발급 판단용.
  Future<Result<bool>> isBeaconDeviceActive(String deviceToken);

  /// 키오스크: 상태 동기화 — device_token이 인증 수단.
  Future<Result<KioskSyncState>> sync(String deviceToken);

  /// 키오스크: PIN 체크인 (KO-4) — check_in_pin Edge Function 경유.
  Future<Result<AttendanceRecord>> checkInByPin({
    required String deviceToken,
    required String sessionId,
    required String studentNumber,
    required String pin,
  });
}

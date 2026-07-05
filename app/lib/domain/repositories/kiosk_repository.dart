import '../../core/result/result.dart';
import '../entities/attendance_record.dart';
import '../entities/kiosk_device.dart';
import '../entities/kiosk_sync.dart';

abstract interface class KioskRepository {
  /// 교사: 기기 토큰 발급 (KO-1). 토큰·secret은 클라이언트에서 Random.secure로 생성.
  Future<Result<IssuedKioskDevice>> issueDevice(String classId);

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

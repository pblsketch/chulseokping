import '../../core/error/failure.dart';
import '../../core/result/result.dart';
import '../../core/utils/secure_random.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/kiosk_device.dart';
import '../../domain/entities/kiosk_sync.dart';
import '../../domain/repositories/kiosk_repository.dart';
import '../datasources/supabase_remote_data_source.dart';
import '../models/attendance_record_dto.dart';
import '../models/kiosk_sync_dto.dart';
import 'failure_mapper.dart';

class KioskRepositoryImpl implements KioskRepository {
  const KioskRepositoryImpl(this._remote);

  final SupabaseRemoteDataSource _remote;

  @override
  Future<Result<IssuedKioskDevice>> issueDevice(String classId) async {
    try {
      final teacherId = _remote.currentUserId;
      if (teacherId == null) return const Err(AuthFailure());
      final deviceToken = SecureRandom.deviceToken();
      final beaconMajor = SecureRandom.beaconMajor();
      await _remote.createKioskDevice(
        classId: classId,
        teacherId: teacherId,
        deviceToken: deviceToken,
        beaconMajor: beaconMajor,
        beaconSecret: SecureRandom.beaconSecret(),
      );
      return Ok(
        IssuedKioskDevice(deviceToken: deviceToken, beaconMajor: beaconMajor),
      );
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }

  @override
  Future<Result<KioskSyncState>> sync(String deviceToken) async {
    try {
      final data = await _remote.invokeCheckIn('kiosk_sync', {
        'device_token': deviceToken,
      });
      return Ok(KioskSyncDto.fromJson(data).toEntity());
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }

  @override
  Future<Result<AttendanceRecord>> checkInByPin({
    required String deviceToken,
    required String sessionId,
    required String studentNumber,
    required String pin,
  }) async {
    try {
      final data = await _remote.invokeCheckIn('check_in_pin', {
        'device_token': deviceToken,
        'session_id': sessionId,
        'student_number': studentNumber,
        'pin': pin,
      });
      final record = (data['record'] as Map).cast<String, dynamic>();
      return Ok(AttendanceRecordDto.fromJson(record).toEntity());
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }
}

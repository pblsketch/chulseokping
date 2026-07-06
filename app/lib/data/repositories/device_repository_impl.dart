import '../../core/result/result.dart';
import '../../domain/entities/device_identity.dart';
import '../../domain/entities/student_device.dart';
import '../../domain/repositories/device_repository.dart';
import '../../domain/services/device_identity_store.dart';
import '../datasources/supabase_remote_data_source.dart';
import 'failure_mapper.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  const DeviceRepositoryImpl(this._remote, this._store, this._platform);

  final SupabaseRemoteDataSource _remote;
  final DeviceIdentityStore _store;

  /// 'android' | 'ios' — DI에서 주입 (테스트 대체 가능)
  final String _platform;

  @override
  Future<Result<DeviceIdentity>> ensureRegistered() async {
    try {
      final stored = await _store.load();
      final response = await _remote.invokeCheckIn('register_device', {
        'platform': _platform,
        // 보관된 uuid가 있으면 멱등 재확인 — 서버가 상태를 알려준다
        if (stored != null) 'device_uuid': stored.uuid,
      });
      final identity = DeviceIdentity(
        uuid: response['device_uuid'] as String,
        status: response['status'] as String,
      );
      await _store.save(identity);
      return Ok(identity);
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }

  @override
  Future<Result<List<StudentDevice>>> devicesOfClass(String classId) async {
    try {
      final rows = await _remote.devicesOfClass(classId);
      return Ok([
        for (final row in rows)
          StudentDevice(
            id: row['id'] as String,
            studentId: row['student_id'] as String,
            studentName:
                ((row['profiles'] as Map?)?['name'] as String?) ?? '이름 없음',
            platform: row['platform'] as String,
            model: row['device_model'] as String?,
            status: row['status'] as String,
            registeredAt: DateTime.parse(row['registered_at'] as String),
          ),
      ]);
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }

  @override
  Future<Result<void>> approveDevice(String deviceId) =>
      _moderate(deviceId, 'approve');

  @override
  Future<Result<void>> revokeDevice(String deviceId) =>
      _moderate(deviceId, 'revoke');

  Future<Result<void>> _moderate(String deviceId, String action) async {
    try {
      await _remote.invokeCheckIn('approve_device', {
        'device_id': deviceId,
        'action': action,
      });
      return const Ok(null);
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }
}

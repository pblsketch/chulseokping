import '../../core/result/result.dart';
import '../entities/teacher_beacon.dart';
import '../repositories/kiosk_repository.dart';
import '../services/teacher_beacon_store.dart';

/// BYOD 세션 진입 시 교사 기기의 비컨 신원 확보:
/// 로컬에 있고 서버에도 살아 있으면 재사용, 아니면(최초·DB 리셋·회수) 재발급.
class EnsureTeacherBeacon {
  const EnsureTeacherBeacon(this._repository, this._store);

  final KioskRepository _repository;
  final TeacherBeaconStore _store;

  Future<Result<TeacherBeaconIdentity>> call(String classId) async {
    final stored = await _store.read(classId);
    if (stored != null) {
      final active = await _repository.isBeaconDeviceActive(stored.deviceToken);
      switch (active) {
        case Ok(value: true):
          return Ok(stored);
        case Ok(value: false):
          await _store.clear(classId); // 서버에서 사라짐/회수 → 재발급
        case Err(:final failure):
          return Err(failure); // 네트워크 오류: 섣불리 재발급하지 않는다
      }
    }

    final issued = await _repository.issueClassBeacon(classId);
    if (issued case Ok(:final value)) {
      await _store.write(classId, value);
    }
    return issued;
  }
}

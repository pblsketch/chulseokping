import '../../core/result/result.dart';
import '../entities/student_device.dart';
import '../repositories/device_repository.dart';

/// P0-2: 교사 승인 UI용 — 담당 학급 기기 목록 (pending 우선 정렬).
class GetClassDevices {
  const GetClassDevices(this._repository);

  final DeviceRepository _repository;

  Future<Result<List<StudentDevice>>> call(String classId) async {
    final result = await _repository.devicesOfClass(classId);
    return result.fold(
      (devices) => Ok(
        [...devices]..sort((a, b) {
          if (a.isPending != b.isPending) return a.isPending ? -1 : 1;
          return b.registeredAt.compareTo(a.registeredAt);
        }),
      ),
      Err.new,
    );
  }
}

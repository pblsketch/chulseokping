import '../../core/result/result.dart';
import '../entities/kiosk_sync.dart';
import '../repositories/kiosk_repository.dart';

class SyncKiosk {
  const SyncKiosk(this._repository);

  final KioskRepository _repository;

  Future<Result<KioskSyncState>> call(String deviceToken) =>
      _repository.sync(deviceToken);
}

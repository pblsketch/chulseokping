import '../entities/device_identity.dart';

/// 기기 신원 보관소 — 구현은 보안저장소(Keychain/Keystore) 필수 (P0-2).
abstract interface class DeviceIdentityStore {
  Future<DeviceIdentity?> load();

  Future<void> save(DeviceIdentity identity);
}

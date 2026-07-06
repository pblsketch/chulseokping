import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/device_identity.dart';
import '../../domain/services/device_identity_store.dart';

/// P0-2: device_uuid 보안 보관 — iOS Keychain / Android Keystore(EncryptedSharedPreferences).
/// Android 재설치 시 소실 → "기기 변경(pending)" 플로우로 자연 유도(의도된 마찰).
class DeviceIdentitySecureStore implements DeviceIdentityStore {
  DeviceIdentitySecureStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _uuidKey = 'device_uuid';
  static const _statusKey = 'device_status';

  @override
  Future<DeviceIdentity?> load() async {
    final uuid = await _storage.read(key: _uuidKey);
    if (uuid == null) return null;
    final status = await _storage.read(key: _statusKey) ?? 'active';
    return DeviceIdentity(uuid: uuid, status: status);
  }

  @override
  Future<void> save(DeviceIdentity identity) async {
    await _storage.write(key: _uuidKey, value: identity.uuid);
    await _storage.write(key: _statusKey, value: identity.status);
  }
}

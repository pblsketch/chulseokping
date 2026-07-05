import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/di/providers.dart';
import '../../core/error/failure.dart';
import '../../core/utils/rotating_code.dart';
import '../../domain/entities/kiosk_sync.dart';

/// 기기 토큰 로컬 저장 (등록 유지용 — 토큰 자체는 서버가 검증).
class KioskTokenStore {
  static const _key = 'kiosk_device_token';

  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(_key);

  Future<void> write(String token) async =>
      (await SharedPreferences.getInstance()).setString(_key, token);

  Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(_key);
}

final kioskTokenStoreProvider = Provider<KioskTokenStore>(
  (ref) => KioskTokenStore(),
);

/// 키오스크 화면 상태.
sealed class KioskState {
  const KioskState();
}

class KioskUnregistered extends KioskState {
  const KioskUnregistered();
}

class KioskReady extends KioskState {
  const KioskReady({required this.deviceToken, required this.sync});

  final String deviceToken;
  final KioskSyncState sync;
}

/// 키오스크 오케스트레이션: 주기 sync(10초) + 세션 활성 시 BLE 광고(minor 5초 회전).
class KioskController extends AsyncNotifier<KioskState> {
  static const syncInterval = Duration(seconds: 10);

  Timer? _syncTimer;
  Timer? _advertiseTimer;
  bool _advertising = false;

  @override
  Future<KioskState> build() async {
    ref.onDispose(() async {
      _syncTimer?.cancel();
      _advertiseTimer?.cancel();
      await ref.read(beaconAdvertiserProvider).stop();
    });

    final token = await ref.watch(kioskTokenStoreProvider).read();
    if (token == null) return const KioskUnregistered();

    final result = await ref.read(syncKioskProvider).call(token);
    return result.fold((sync) {
      _schedule(token);
      _updateAdvertising(sync);
      return KioskReady(deviceToken: token, sync: sync);
    }, (_) => const KioskUnregistered());
  }

  /// 등록: 성공 시 null, 실패 시 Failure (폼 표시용).
  Future<Failure?> register(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return const ValidationFailure('기기 토큰을 입력해 주세요');
    final result = await ref.read(syncKioskProvider).call(trimmed);
    return result.fold((sync) {
      ref.read(kioskTokenStoreProvider).write(trimmed);
      state = AsyncData(KioskReady(deviceToken: trimmed, sync: sync));
      _schedule(trimmed);
      _updateAdvertising(sync);
      return null;
    }, (failure) => failure);
  }

  Future<void> unregister() async {
    _syncTimer?.cancel();
    await _stopAdvertising();
    await ref.read(kioskTokenStoreProvider).clear();
    state = const AsyncData(KioskUnregistered());
  }

  Future<void> refresh() async {
    final current = state.value;
    if (current is! KioskReady) return;
    await _sync(current.deviceToken);
  }

  void _schedule(String token) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(syncInterval, (_) => _sync(token));
  }

  Future<void> _sync(String token) async {
    final result = await ref.read(syncKioskProvider).call(token);
    result.fold(
      (sync) {
        state = AsyncData(KioskReady(deviceToken: token, sync: sync));
        _updateAdvertising(sync);
      },
      (_) {
        // 일시 네트워크 오류: 기존 상태 유지 (BE-5 만료는 다음 sync에서 반영)
      },
    );
  }

  /// 세션 활성 ↔ BLE 광고 동기화 (KO-3, BE-5 좀비 광고 방지).
  Future<void> _updateAdvertising(KioskSyncState sync) async {
    final advertiser = ref.read(beaconAdvertiserProvider);
    final session = sync.activeSession;
    if (session == null) {
      await _stopAdvertising();
      return;
    }
    if (!await advertiser.isSupported()) return;
    if (_advertising) return; // 회전은 아래 타이머가 담당

    _advertising = true;
    Future<void> rotate() async {
      final minor = RotatingCode.beaconMinor(
        sync.beaconSecret,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
      );
      await advertiser.start(major: sync.beaconMajor, minor: minor);
    }

    await rotate();
    _advertiseTimer = Timer.periodic(
      const Duration(seconds: RotatingCode.periodSeconds),
      (_) => rotate(),
    );
  }

  Future<void> _stopAdvertising() async {
    _advertiseTimer?.cancel();
    _advertiseTimer = null;
    _advertising = false;
    await ref.read(beaconAdvertiserProvider).stop();
  }
}

final kioskControllerProvider =
    AsyncNotifierProvider<KioskController, KioskState>(KioskController.new);

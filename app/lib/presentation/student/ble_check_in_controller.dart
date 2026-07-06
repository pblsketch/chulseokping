import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/services/beacon_scanner.dart';
import '../../domain/usecases/beacon_sighting_stabilizer.dart';

/// BLE 자동 출석 상태 (ST-2/ST-3).
sealed class BleCheckInState {
  const BleCheckInState();
}

class BleIdle extends BleCheckInState {
  const BleIdle();
}

/// 권한 거부/미지원/오류 — QR이 1급 폴백 (ST-4)
class BleUnavailable extends BleCheckInState {
  const BleUnavailable(this.message);

  final String message;
}

class BleScanning extends BleCheckInState {
  const BleScanning();
}

/// 제한 시간 안에 비컨을 못 찾음 — 무한 "감지 중" 대신 QR 안내 + 재시도 (ST-4).
class BleNotFound extends BleCheckInState {
  const BleNotFound();
}

/// iPhone: 감지됨 — 원탭 확인 대기 (백그라운드 자동은 미보장, 정직 고지)
class BleDetected extends BleCheckInState {
  const BleDetected(this.sighting);

  final BeaconSighting sighting;
}

class BleSubmitting extends BleCheckInState {
  const BleSubmitting();
}

class BleSuccess extends BleCheckInState {
  const BleSuccess(this.record);

  final AttendanceRecord record;
}

class BleFailed extends BleCheckInState {
  const BleFailed(this.message);

  final String message;
}

/// 감지 → 안정 판정 → (Android) 자동 제출 / (iPhone) 원탭 확인.
/// payload는 (session_id, major, minor)만 — 좌표·RSSI raw는 전송하지 않는다.
class BleCheckInController extends Notifier<BleCheckInState> {
  BleCheckInController(this._sessionId);

  /// 이 시간 안에 안정 감지가 없으면 BleNotFound (무한 스피너 방지).
  /// 테스트에서만 짧게 조정한다.
  @visibleForTesting
  static Duration scanTimeout = const Duration(seconds: 25);

  final String _sessionId;
  StreamSubscription<List<BeaconSighting>>? _subscription;
  Timer? _timeoutTimer;
  BeaconSightingStabilizer _stabilizer = BeaconSightingStabilizer();

  @override
  BleCheckInState build() {
    ref.onDispose(() {
      _subscription?.cancel();
      _timeoutTimer?.cancel();
    });
    return const BleIdle();
  }

  Future<void> start() async {
    if (state is! BleIdle) return;
    final scanner = ref.read(beaconScannerProvider);
    if (!await scanner.prepare()) {
      state = const BleUnavailable('비컨 감지를 쓸 수 없어요 — QR로 출석해 주세요');
      return;
    }
    _stabilizer = BeaconSightingStabilizer();
    state = const BleScanning();
    _timeoutTimer = Timer(scanTimeout, () async {
      if (state is! BleScanning) return;
      await _stopScan();
      state = const BleNotFound();
    });
    _subscription = scanner.ranging().listen(
      (sightings) {
        if (state is! BleScanning) return;
        final stable = _stabilizer.add(sightings);
        if (stable == null) return;
        if (ref.read(isAndroidProvider)) {
          _submit(stable); // ST-2: Android 자동 출석
        } else {
          state = BleDetected(stable); // ST-3: iPhone 원탭 확인
        }
      },
      onError: (_) {
        state = const BleUnavailable('비컨 감지 중 오류 — QR로 출석해 주세요');
      },
    );
  }

  /// BleNotFound에서 "다시 감지" (교사가 뒤늦게 비컨을 켠 경우 등).
  Future<void> retry() async {
    if (state is! BleNotFound) return;
    state = const BleIdle();
    await start();
  }

  Future<void> _stopScan() async {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    await _subscription?.cancel();
    _subscription = null;
  }

  /// iPhone 원탭 확인 (ST-3)
  Future<void> confirm() async {
    final current = state;
    if (current is BleDetected) await _submit(current.sighting);
  }

  Future<void> _submit(BeaconSighting sighting) async {
    await _stopScan();
    state = const BleSubmitting();
    final result = await ref
        .read(checkInByBleProvider)
        .call(
          sessionId: _sessionId,
          major: sighting.major,
          minor: sighting.minor,
        );
    result.fold(
      (record) => state = BleSuccess(record),
      (failure) => state = BleFailed(failure.message),
    );
  }
}

final bleCheckInControllerProvider = NotifierProvider.autoDispose
    .family<BleCheckInController, BleCheckInState, String>(
      BleCheckInController.new,
    );

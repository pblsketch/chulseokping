import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/result/result.dart';
import '../../core/utils/rotating_code.dart';

/// BYOD 세션 중 교사 기기 비컨 송신 상태.
sealed class TeacherBeaconState {
  const TeacherBeaconState();
}

class TeacherBeaconIdle extends TeacherBeaconState {
  const TeacherBeaconIdle();
}

/// 미지원 기기/권한 거부/등록 실패 — 학생은 QR로 출석 (정직 고지).
class TeacherBeaconOff extends TeacherBeaconState {
  const TeacherBeaconOff(this.message);

  final String message;
}

class TeacherBeaconOn extends TeacherBeaconState {
  const TeacherBeaconOn(this.major);

  final int major;
}

/// 키오스크가 없는 BYOD 교실에서 교사 기기가 유일한 비컨 송신원 (ST-2/ST-3 전제).
/// 세션 화면에 있는 동안만 광고하고, 화면을 떠나면 자동 정지(좀비 광고 방지).
class TeacherBeaconController extends Notifier<TeacherBeaconState> {
  TeacherBeaconController(this._classId);

  final String _classId;
  Timer? _rotateTimer;

  @override
  TeacherBeaconState build() {
    ref.onDispose(() async {
      _rotateTimer?.cancel();
      await ref.read(beaconAdvertiserProvider).stop();
    });
    return const TeacherBeaconIdle();
  }

  Future<void> start() async {
    if (state is! TeacherBeaconIdle) return;
    final advertiser = ref.read(beaconAdvertiserProvider);

    if (!await advertiser.isSupported()) {
      state = const TeacherBeaconOff('이 기기는 비컨 송신 미지원 — 학생은 QR로 출석해요');
      return;
    }
    if (!await advertiser.prepare()) {
      state = const TeacherBeaconOff('블루투스 권한이 없어 비컨을 못 켰어요 — 학생은 QR로 출석해요');
      return;
    }

    final identity = await ref.read(ensureTeacherBeaconProvider).call(_classId);
    switch (identity) {
      case Ok(:final value):
        Future<void> rotate() => advertiser.start(
          major: value.beaconMajor,
          minor: RotatingCode.beaconMinor(
            value.beaconSecret,
            timestampMs: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        try {
          await rotate();
        } catch (_) {
          state = const TeacherBeaconOff('비컨 송신 시작 실패 — 학생은 QR로 출석해요');
          return;
        }
        _rotateTimer = Timer.periodic(
          const Duration(seconds: RotatingCode.periodSeconds),
          (_) => rotate(),
        );
        state = TeacherBeaconOn(value.beaconMajor);
      case Err():
        state = const TeacherBeaconOff('비컨 등록 실패 — 학생은 QR로 출석해요');
    }
  }
}

final teacherBeaconControllerProvider = NotifierProvider.autoDispose
    .family<TeacherBeaconController, TeacherBeaconState, String>(
      TeacherBeaconController.new,
    );

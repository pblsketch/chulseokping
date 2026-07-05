import 'package:flutter/services.dart';

/// KO-6 소프트 화면 고정 — Android screen pinning(lockTask, 비-MDM).
/// 완전 잠금이 아니며 우회 가능함을 UX·문서에 명시한다 (PRD KO-6).
/// 네이티브 채널이 없거나 실패하면 조용히 false — 키오스크는 계속 동작한다.
abstract final class KioskLock {
  static const MethodChannel _channel = MethodChannel('chulseokping/kiosk');

  static Future<bool> enable() async {
    try {
      await _channel.invokeMethod<void>('startLockTask');
      return true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<void> disable() async {
    try {
      await _channel.invokeMethod<void>('stopLockTask');
    } on PlatformException {
      // 이미 해제됐거나 미지원 — 무시
    } on MissingPluginException {
      // 데스크톱/테스트 환경 — 무시
    }
  }
}

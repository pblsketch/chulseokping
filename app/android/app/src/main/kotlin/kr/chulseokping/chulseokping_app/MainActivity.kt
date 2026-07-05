package kr.chulseokping.chulseokping_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// KO-6 소프트 화면 고정: screen pinning(lockTask, 비-MDM).
// 완전 잠금이 아님 — 사용자가 시스템 제스처로 해제할 수 있다(PRD에 명시된 한계).
class MainActivity : FlutterActivity() {
    private val channelName = "chulseokping/kiosk"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startLockTask" -> {
                        try {
                            startLockTask()
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("LOCK_TASK_FAILED", e.message, null)
                        }
                    }
                    "stopLockTask" -> {
                        try {
                            stopLockTask()
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("UNLOCK_TASK_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}

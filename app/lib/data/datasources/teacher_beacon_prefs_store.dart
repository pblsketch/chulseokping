import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/teacher_beacon.dart';
import '../../domain/services/teacher_beacon_store.dart';

/// 학급별 교사 비컨 신원 로컬 보관 (SharedPreferences).
/// secret은 서버 검증용 사본일 뿐 — 서버가 진실 원천이며 기기 밖 전송 없음.
class TeacherBeaconPrefsStore implements TeacherBeaconStore {
  static String _key(String classId) => 'teacher_beacon_$classId';

  @override
  Future<TeacherBeaconIdentity?> read(String classId) async {
    final raw = (await SharedPreferences.getInstance()).getString(
      _key(classId),
    );
    if (raw == null) return null;
    try {
      final map = (jsonDecode(raw) as Map).cast<String, dynamic>();
      return TeacherBeaconIdentity(
        deviceToken: map['deviceToken'] as String,
        beaconMajor: map['beaconMajor'] as int,
        beaconSecret: map['beaconSecret'] as String,
      );
    } catch (_) {
      return null; // 손상된 값은 재발급 경로로
    }
  }

  @override
  Future<void> write(String classId, TeacherBeaconIdentity identity) async {
    await (await SharedPreferences.getInstance()).setString(
      _key(classId),
      jsonEncode({
        'deviceToken': identity.deviceToken,
        'beaconMajor': identity.beaconMajor,
        'beaconSecret': identity.beaconSecret,
      }),
    );
  }

  @override
  Future<void> clear(String classId) async {
    await (await SharedPreferences.getInstance()).remove(_key(classId));
  }
}

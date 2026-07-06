import '../entities/teacher_beacon.dart';

/// 교사 기기의 학급별 비컨 신원 로컬 보관 — 구현은 data 레이어(SharedPreferences).
/// secret은 이 기기(교사 소유) 밖으로 나가지 않는다.
abstract interface class TeacherBeaconStore {
  Future<TeacherBeaconIdentity?> read(String classId);

  Future<void> write(String classId, TeacherBeaconIdentity identity);

  Future<void> clear(String classId);
}

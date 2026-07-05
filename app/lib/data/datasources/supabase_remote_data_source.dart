import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/attendance_record_dto.dart';
import '../models/class_room_dto.dart';
import '../models/profile_dto.dart';
import '../models/session_dto.dart';

/// Supabase I/O 격리 지점 (ARCHITECTURE §2.3).
/// 계약(BE-0): 출석 쓰기는 `functions.invoke`만 — 이 클래스에도 attendance INSERT 코드를 두지 않는다.
class SupabaseRemoteDataSource {
  SupabaseRemoteDataSource(this._client);

  final SupabaseClient _client;

  // ── Auth ──
  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.user!.id;
  }

  Future<void> signOut() => _client.auth.signOut();

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<ProfileDto?> fetchProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select('id, role, name, student_number')
        .eq('id', userId)
        .maybeSingle();
    return row == null ? null : ProfileDto.fromJson(row);
  }

  // ── Roster ──
  Future<List<ClassRoomDto>> classesOfTeacher(String teacherId) async {
    final rows = await _client
        .from('classes')
        .select('id, school_id, teacher_id, name, invite_code')
        .eq('teacher_id', teacherId);
    return rows.map(ClassRoomDto.fromJson).toList();
  }

  Future<List<ClassRoomDto>> classesOfStudent(String studentId) async {
    final rows = await _client
        .from('classes')
        .select(
          'id, school_id, teacher_id, name, invite_code, '
          'student_classes!inner(student_id)',
        )
        .eq('student_classes.student_id', studentId);
    return rows.map(ClassRoomDto.fromJson).toList();
  }

  Future<List<ProfileDto>> studentsOf(String classId) async {
    final rows = await _client
        .from('profiles')
        .select(
          'id, role, name, student_number, '
          'student_classes!inner(class_id)',
        )
        .eq('role', 'student')
        .eq('student_classes.class_id', classId);
    return rows.map(ProfileDto.fromJson).toList();
  }

  /// RLS(teaches_student)가 교사 담당 학생 범위로 제한한다.
  Future<Set<String>> consentedStudentIds() async {
    final rows = await _client.from('consents').select('student_id');
    return rows.map((r) => r['student_id'] as String).toSet();
  }

  // ── Sessions ──
  Future<SessionDto> startSession({
    required String classId,
    required String teacherId,
    required String type,
    int? period,
    required String mode,
  }) async {
    final row = await _client
        .from('sessions')
        .insert({
          'class_id': classId,
          'teacher_id': teacherId,
          'type': type,
          'period': period,
          'mode': mode,
        })
        .select()
        .single();
    return SessionDto.fromJson(row);
  }

  Future<SessionDto> endSession(String sessionId) async {
    final row = await _client
        .from('sessions')
        .update({
          'status': 'ENDED',
          'ended_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', sessionId)
        .select()
        .single();
    return SessionDto.fromJson(row);
  }

  Future<SessionDto?> activeSessionFor(String classId) async {
    final row = await _client
        .from('sessions')
        .select()
        .eq('class_id', classId)
        .eq('status', 'ACTIVE')
        .order('started_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : SessionDto.fromJson(row);
  }

  /// 교사 전용(RLS) — 회전 QR 표시용 secret
  Future<String?> classSecret(String classId) async {
    final row = await _client
        .from('class_secrets')
        .select('qr_secret')
        .eq('class_id', classId)
        .maybeSingle();
    return row == null ? null : row['qr_secret'] as String;
  }

  // ── Kiosk ──
  /// 교사 발급 (KO-1) — RLS(kiosk_devices_teacher_all)가 자기 학급으로 제한.
  Future<void> createKioskDevice({
    required String classId,
    required String teacherId,
    required String deviceToken,
    required int beaconMajor,
    required String beaconSecret,
  }) async {
    await _client.from('kiosk_devices').insert({
      'class_id': classId,
      'teacher_id': teacherId,
      'device_token': deviceToken,
      'beacon_major': beaconMajor,
      'beacon_secret': beaconSecret,
    });
  }

  // ── Attendance (쓰기 = Edge Function 전용) ──
  Future<Map<String, dynamic>> invokeCheckIn(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.functions.invoke(functionName, body: body);
    return (response.data as Map).cast<String, dynamic>();
  }

  Stream<List<AttendanceRecordDto>> watchSessionLogs(String sessionId) {
    return _client
        .from('attendance_logs')
        .stream(primaryKey: ['id'])
        .eq('session_id', sessionId)
        .map((rows) => rows.map(AttendanceRecordDto.fromJson).toList());
  }

  Future<List<AttendanceRecordDto>> recordsBetween({
    required String classId,
    required DateTime startInclusive,
    required DateTime endInclusive,
  }) async {
    final rows = await _client
        .from('attendance_logs')
        .select('*, sessions!inner(date)')
        .eq('class_id', classId)
        .gte('sessions.date', startInclusive.toIso8601String())
        .lte('sessions.date', endInclusive.toIso8601String());
    return rows.map(AttendanceRecordDto.fromJson).toList();
  }
}

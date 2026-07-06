import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/attendance_record_dto.dart';
import '../models/class_room_dto.dart';
import '../models/consent_dto.dart';
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

  // ── Auth (M5 계정·온보딩) ──

  /// 교사 회원가입. 반환 true = 세션 즉시 발급(이메일 인증 비활성 환경).
  Future<bool> signUpTeacher({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    return response.session != null;
  }

  /// 가입 확인 OTP 검증 — 성공 시 세션 발급
  Future<void> verifySignUpOtp({
    required String email,
    required String token,
  }) =>
      _client.auth.verifyOTP(type: OtpType.signup, email: email, token: token);

  /// 본인 프로필 행 생성 (RLS profiles_insert_own)
  Future<void> insertOwnProfile({
    required String userId,
    required String role,
    required String name,
  }) => _client.from('profiles').insert({
    'id': userId,
    'role': role,
    'name': name,
  });

  Future<void> requestPasswordReset(String email) =>
      _client.auth.resetPasswordForEmail(email);

  /// 재설정 OTP 검증 — 성공 시 임시 세션 발급(이어서 updatePassword)
  Future<void> verifyRecoveryOtp({
    required String email,
    required String token,
  }) => _client.auth.verifyOTP(
    type: OtpType.recovery,
    email: email,
    token: token,
  );

  Future<void> updatePassword(String newPassword) =>
      _client.auth.updateUser(UserAttributes(password: newPassword));

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

  Future<List<ConsentDto>> fetchConsents() async {
    final rows = await _client.from('consents').select();
    return rows.map(ConsentDto.fromJson).toList();
  }

  /// PI-2: 보호자 동의 확인 기록 (RLS: 담당 학생 + 확인자=본인)
  Future<ConsentDto> insertConsent({
    required String studentId,
    required String policyVersion,
    required String teacherId,
  }) async {
    final row = await _client
        .from('consents')
        .insert({
          'student_id': studentId,
          'policy_version': policyVersion,
          'guardian_confirmed_by': teacherId,
        })
        .select()
        .single();
    return ConsentDto.fromJson(row);
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

  /// 학생앱 실시간 세션 감지용. 교사가 세션을 종료하고 새로 시작해도
  /// 학생이 화면을 새로고침할 필요 없이 최신 활성 세션으로 갱신된다
  /// (예전엔 1회성 조회라 앱을 다시 열기 전까진 종료된 세션 ID를 들고 있었다).
  Stream<SessionDto?> watchActiveSession(String classId) {
    return _client
        .from('sessions')
        .stream(primaryKey: ['id'])
        .eq('class_id', classId)
        .map((rows) {
          final active = rows.where((r) => r['status'] == 'ACTIVE').toList()
            ..sort(
              (a, b) => (b['started_at'] as String).compareTo(
                a['started_at'] as String,
              ),
            );
          return active.isEmpty ? null : SessionDto.fromJson(active.first);
        });
  }

  Future<List<SessionDto>> sessionsBetween({
    required String classId,
    required DateTime startInclusive,
    required DateTime endInclusive,
  }) async {
    final rows = await _client
        .from('sessions')
        .select()
        .eq('class_id', classId)
        .gte('date', startInclusive.toIso8601String())
        .lte('date', endInclusive.toIso8601String())
        .order('date');
    return rows.map(SessionDto.fromJson).toList();
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

  /// 교사 전용(RLS) — 자기 기기 비컨 등록이 아직 유효한지 (BYOD 재사용 판단)
  Future<bool> kioskDeviceActive(String deviceToken) async {
    final row = await _client
        .from('kiosk_devices')
        .select('id')
        .eq('device_token', deviceToken)
        .eq('revoked', false)
        .maybeSingle();
    return row != null;
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

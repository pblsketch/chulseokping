import '../../core/result/result.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/services/device_identity_store.dart';
import '../../domain/value_objects/absence_reason.dart';
import '../../domain/value_objects/attendance_status.dart';
import '../datasources/supabase_remote_data_source.dart';
import '../models/attendance_record_dto.dart';
import 'failure_mapper.dart';

/// 계약(BE-0): 모든 쓰기는 검증 Edge Function invoke — 직접 INSERT/UPDATE 없음.
class AttendanceRepositoryImpl implements AttendanceRepository {
  const AttendanceRepositoryImpl(this._remote, {this._deviceStore});

  final SupabaseRemoteDataSource _remote;

  /// P0-2: QR/BLE 체크인에 기기 uuid 동봉 (서버 로그-온리 판정용). null이면 미동봉.
  final DeviceIdentityStore? _deviceStore;

  Future<String?> _deviceUuid() async {
    final identity = await _deviceStore?.load();
    return identity?.uuid;
  }

  Future<Result<AttendanceRecord>> _invoke(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    try {
      final data = await _remote.invokeCheckIn(functionName, body);
      final record = (data['record'] as Map).cast<String, dynamic>();
      return Ok(AttendanceRecordDto.fromJson(record).toEntity());
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }

  @override
  Future<Result<AttendanceRecord>> checkInByQr({
    required String sessionId,
    required String code,
  }) async {
    return _invoke('check_in_qr', {
      'session_id': sessionId,
      'code': code,
      'device_uuid': ?await _deviceUuid(),
    });
  }

  @override
  Future<Result<AttendanceRecord>> checkInByBle({
    required String sessionId,
    required int major,
    required int minor,
  }) async {
    return _invoke('check_in_ble', {
      'session_id': sessionId,
      'major': major,
      'minor': minor,
      'device_uuid': ?await _deviceUuid(),
    });
  }

  @override
  Future<Result<AttendanceRecord>> updateStatus({
    required String recordId,
    required AttendanceStatus status,
    AbsenceReason? reason,
    RecognizedCode? reasonCode,
    String? reasonDetail,
  }) {
    return _invoke('update_attendance', {
      'record_id': recordId,
      'status': status.wireName,
      'reason': reason?.wireName,
      'reason_code': reasonCode?.wireName,
      'reason_detail': reasonDetail,
    });
  }

  @override
  Future<Result<AttendanceRecord>> markManual({
    required String sessionId,
    required String studentId,
    required AttendanceStatus status,
    AbsenceReason? reason,
    RecognizedCode? reasonCode,
    String? reasonDetail,
  }) {
    return _invoke('update_attendance', {
      'session_id': sessionId,
      'student_id': studentId,
      'status': status.wireName,
      'reason': reason?.wireName,
      'reason_code': reasonCode?.wireName,
      'reason_detail': reasonDetail,
    });
  }

  @override
  Stream<List<AttendanceRecord>> watchSession(String sessionId) {
    return _remote
        .watchSessionLogs(sessionId)
        .map((dtos) => dtos.map((dto) => dto.toEntity()).toList());
  }

  @override
  Stream<AttendanceRecord?> watchMyRecord(String sessionId) {
    final studentId = _remote.currentUserId;
    if (studentId == null) return Stream.value(null);
    return _remote
        .watchSessionLogs(sessionId)
        .map(
          (dtos) => dtos
              .where((dto) => dto.studentId == studentId)
              .map((dto) => dto.toEntity())
              .firstOrNull,
        );
  }

  @override
  Future<Result<List<AttendanceRecord>>> monthlyRecords({
    required String classId,
    required int year,
    required int month,
  }) async {
    try {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 0); // 해당 월 말일
      final dtos = await _remote.recordsBetween(
        classId: classId,
        startInclusive: start,
        endInclusive: end,
      );
      return Ok(dtos.map((dto) => dto.toEntity()).toList());
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }
}

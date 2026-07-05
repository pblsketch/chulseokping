import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/attendance_record.dart';
import '../../domain/value_objects/absence_reason.dart';
import '../../domain/value_objects/attendance_status.dart';
import '../../domain/value_objects/check_in_mode.dart';

part 'attendance_record_dto.freezed.dart';
part 'attendance_record_dto.g.dart';

// 계약(PI-3): 좌표성 필드를 추가하지 않는다 — 회귀 테스트가 lib/ 전체를 스캔한다.
@freezed
abstract class AttendanceRecordDto with _$AttendanceRecordDto {
  const AttendanceRecordDto._();

  const factory AttendanceRecordDto({
    required String id,
    @JsonKey(name: 'student_id') required String studentId,
    @JsonKey(name: 'class_id') required String classId,
    @JsonKey(name: 'session_id') required String sessionId,
    required String method,
    required String status,
    String? reason,
    @JsonKey(name: 'reason_code') String? reasonCode,
    @JsonKey(name: 'reason_detail') String? reasonDetail,
    @JsonKey(name: 'document_submitted') @Default(false) bool documentSubmitted,
    @JsonKey(name: 'neis_excluded') @Default(false) bool neisExcluded,
    @JsonKey(name: 'kiosk_device_id') String? kioskDeviceId,
    @JsonKey(name: 'check_in_time') required DateTime checkInTime,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'updated_by') String? updatedBy,
  }) = _AttendanceRecordDto;

  factory AttendanceRecordDto.fromJson(Map<String, dynamic> json) =>
      _$AttendanceRecordDtoFromJson(json);

  AttendanceRecord toEntity() => AttendanceRecord(
    id: id,
    studentId: studentId,
    classId: classId,
    sessionId: sessionId,
    method: CheckInMode.fromWire(method),
    status: AttendanceStatus.fromWire(status),
    reason: reason == null ? null : AbsenceReason.fromWire(reason!),
    reasonCode: reasonCode == null
        ? null
        : RecognizedCode.fromWire(reasonCode!),
    reasonDetail: reasonDetail,
    documentSubmitted: documentSubmitted,
    neisExcluded: neisExcluded,
    kioskDeviceId: kioskDeviceId,
    checkInTime: checkInTime,
    updatedAt: updatedAt,
    updatedBy: updatedBy,
  );
}

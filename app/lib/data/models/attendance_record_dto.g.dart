// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_record_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AttendanceRecordDto _$AttendanceRecordDtoFromJson(Map<String, dynamic> json) =>
    _AttendanceRecordDto(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      classId: json['class_id'] as String,
      sessionId: json['session_id'] as String,
      method: json['method'] as String,
      status: json['status'] as String,
      reason: json['reason'] as String?,
      reasonCode: json['reason_code'] as String?,
      reasonDetail: json['reason_detail'] as String?,
      documentSubmitted: json['document_submitted'] as bool? ?? false,
      neisExcluded: json['neis_excluded'] as bool? ?? false,
      kioskDeviceId: json['kiosk_device_id'] as String?,
      checkInTime: DateTime.parse(json['check_in_time'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      updatedBy: json['updated_by'] as String?,
    );

Map<String, dynamic> _$AttendanceRecordDtoToJson(
  _AttendanceRecordDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'student_id': instance.studentId,
  'class_id': instance.classId,
  'session_id': instance.sessionId,
  'method': instance.method,
  'status': instance.status,
  'reason': instance.reason,
  'reason_code': instance.reasonCode,
  'reason_detail': instance.reasonDetail,
  'document_submitted': instance.documentSubmitted,
  'neis_excluded': instance.neisExcluded,
  'kiosk_device_id': instance.kioskDeviceId,
  'check_in_time': instance.checkInTime.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'updated_by': instance.updatedBy,
};

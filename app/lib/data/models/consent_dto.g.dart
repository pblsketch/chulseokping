// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consent_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ConsentDto _$ConsentDtoFromJson(Map<String, dynamic> json) => _ConsentDto(
  id: json['id'] as String,
  studentId: json['student_id'] as String,
  policyVersion: json['policy_version'] as String,
  guardianConfirmedBy: json['guardian_confirmed_by'] as String?,
  consentedAt: DateTime.parse(json['consented_at'] as String),
);

Map<String, dynamic> _$ConsentDtoToJson(_ConsentDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'student_id': instance.studentId,
      'policy_version': instance.policyVersion,
      'guardian_confirmed_by': instance.guardianConfirmedBy,
      'consented_at': instance.consentedAt.toIso8601String(),
    };

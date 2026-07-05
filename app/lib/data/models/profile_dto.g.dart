// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProfileDto _$ProfileDtoFromJson(Map<String, dynamic> json) => _ProfileDto(
  id: json['id'] as String,
  role: json['role'] as String,
  name: json['name'] as String,
  studentNumber: json['student_number'] as String?,
);

Map<String, dynamic> _$ProfileDtoToJson(_ProfileDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'role': instance.role,
      'name': instance.name,
      'student_number': instance.studentNumber,
    };

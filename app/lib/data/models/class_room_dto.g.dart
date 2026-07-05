// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_room_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ClassRoomDto _$ClassRoomDtoFromJson(Map<String, dynamic> json) =>
    _ClassRoomDto(
      id: json['id'] as String,
      schoolId: json['school_id'] as String?,
      teacherId: json['teacher_id'] as String,
      name: json['name'] as String,
      inviteCode: json['invite_code'] as String,
    );

Map<String, dynamic> _$ClassRoomDtoToJson(_ClassRoomDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'school_id': instance.schoolId,
      'teacher_id': instance.teacherId,
      'name': instance.name,
      'invite_code': instance.inviteCode,
    };

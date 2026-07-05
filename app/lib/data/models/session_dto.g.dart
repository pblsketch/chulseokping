// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SessionDto _$SessionDtoFromJson(Map<String, dynamic> json) => _SessionDto(
  id: json['id'] as String,
  classId: json['class_id'] as String,
  teacherId: json['teacher_id'] as String,
  type: json['type'] as String,
  period: (json['period'] as num?)?.toInt(),
  date: DateTime.parse(json['date'] as String),
  mode: json['mode'] as String,
  status: json['status'] as String,
  startedAt: DateTime.parse(json['started_at'] as String),
  endedAt: json['ended_at'] == null
      ? null
      : DateTime.parse(json['ended_at'] as String),
);

Map<String, dynamic> _$SessionDtoToJson(_SessionDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'class_id': instance.classId,
      'teacher_id': instance.teacherId,
      'type': instance.type,
      'period': instance.period,
      'date': instance.date.toIso8601String(),
      'mode': instance.mode,
      'status': instance.status,
      'started_at': instance.startedAt.toIso8601String(),
      'ended_at': instance.endedAt?.toIso8601String(),
    };

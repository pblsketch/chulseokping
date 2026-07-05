import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/class_room.dart';

part 'class_room_dto.freezed.dart';
part 'class_room_dto.g.dart';

@freezed
abstract class ClassRoomDto with _$ClassRoomDto {
  const ClassRoomDto._();

  const factory ClassRoomDto({
    required String id,
    @JsonKey(name: 'school_id') String? schoolId,
    @JsonKey(name: 'teacher_id') required String teacherId,
    required String name,
    @JsonKey(name: 'invite_code') required String inviteCode,
  }) = _ClassRoomDto;

  factory ClassRoomDto.fromJson(Map<String, dynamic> json) =>
      _$ClassRoomDtoFromJson(json);

  ClassRoom toEntity() => ClassRoom(
    id: id,
    teacherId: teacherId,
    name: name,
    inviteCode: inviteCode,
    schoolId: schoolId,
  );
}

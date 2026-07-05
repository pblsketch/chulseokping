import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/session.dart';
import '../../domain/value_objects/session_type.dart';

part 'session_dto.freezed.dart';
part 'session_dto.g.dart';

@freezed
abstract class SessionDto with _$SessionDto {
  const SessionDto._();

  const factory SessionDto({
    required String id,
    @JsonKey(name: 'class_id') required String classId,
    @JsonKey(name: 'teacher_id') required String teacherId,
    required String type,
    int? period,
    required DateTime date,
    required String mode,
    required String status,
    @JsonKey(name: 'started_at') required DateTime startedAt,
    @JsonKey(name: 'ended_at') DateTime? endedAt,
  }) = _SessionDto;

  factory SessionDto.fromJson(Map<String, dynamic> json) =>
      _$SessionDtoFromJson(json);

  Session toEntity() => Session(
    id: id,
    classId: classId,
    teacherId: teacherId,
    type: SessionType.fromWire(type),
    period: period,
    date: date,
    mode: SessionMode.fromWire(mode),
    status: SessionStatus.fromWire(status),
    startedAt: startedAt,
    endedAt: endedAt,
  );
}

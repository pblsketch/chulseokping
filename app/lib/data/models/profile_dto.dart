import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/student.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/value_objects/user_role.dart';

part 'profile_dto.freezed.dart';
part 'profile_dto.g.dart';

@freezed
abstract class ProfileDto with _$ProfileDto {
  const ProfileDto._();

  const factory ProfileDto({
    required String id,
    required String role,
    required String name,
    @JsonKey(name: 'student_number') String? studentNumber,
  }) = _ProfileDto;

  factory ProfileDto.fromJson(Map<String, dynamic> json) =>
      _$ProfileDtoFromJson(json);

  UserProfile toUserProfile() => UserProfile(
    id: id,
    role: UserRole.fromWire(role),
    name: name,
    studentNumber: studentNumber,
  );

  /// 명단 표시용 학생 entity (동의 여부는 RosterRepository가 consents로 채운다)
  Student toStudent({required bool consentConfirmed}) => Student(
    id: id,
    name: name,
    studentNumber: studentNumber ?? '',
    consentConfirmed: consentConfirmed,
  );
}

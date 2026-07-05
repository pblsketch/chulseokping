import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/consent_record.dart';

part 'consent_dto.freezed.dart';
part 'consent_dto.g.dart';

@freezed
abstract class ConsentDto with _$ConsentDto {
  const ConsentDto._();

  const factory ConsentDto({
    required String id,
    @JsonKey(name: 'student_id') required String studentId,
    @JsonKey(name: 'policy_version') required String policyVersion,
    @JsonKey(name: 'guardian_confirmed_by') String? guardianConfirmedBy,
    @JsonKey(name: 'consented_at') required DateTime consentedAt,
  }) = _ConsentDto;

  factory ConsentDto.fromJson(Map<String, dynamic> json) =>
      _$ConsentDtoFromJson(json);

  ConsentRecord toEntity() => ConsentRecord(
    id: id,
    studentId: studentId,
    policyVersion: policyVersion,
    consentedAt: consentedAt,
    guardianConfirmedBy: guardianConfirmedBy,
  );
}

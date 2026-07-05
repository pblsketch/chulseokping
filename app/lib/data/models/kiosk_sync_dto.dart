import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/kiosk_sync.dart';
import '../../domain/value_objects/session_type.dart';

part 'kiosk_sync_dto.freezed.dart';
part 'kiosk_sync_dto.g.dart';

@freezed
abstract class KioskSessionDto with _$KioskSessionDto {
  const KioskSessionDto._();

  const factory KioskSessionDto({
    required String id,
    required String type,
    int? period,
  }) = _KioskSessionDto;

  factory KioskSessionDto.fromJson(Map<String, dynamic> json) =>
      _$KioskSessionDtoFromJson(json);

  KioskSession toEntity() =>
      KioskSession(id: id, type: SessionType.fromWire(type), period: period);
}

@freezed
abstract class KioskSyncDto with _$KioskSyncDto {
  const KioskSyncDto._();

  const factory KioskSyncDto({
    @JsonKey(name: 'device_id') required String deviceId,
    @JsonKey(name: 'class_id') required String classId,
    @JsonKey(name: 'class_name') required String className,
    @JsonKey(name: 'beacon_major') required int beaconMajor,
    @JsonKey(name: 'beacon_secret') required String beaconSecret,
    @JsonKey(name: 'qr_secret') String? qrSecret,
    KioskSessionDto? session,
  }) = _KioskSyncDto;

  factory KioskSyncDto.fromJson(Map<String, dynamic> json) =>
      _$KioskSyncDtoFromJson(json);

  KioskSyncState toEntity() => KioskSyncState(
    deviceId: deviceId,
    classId: classId,
    className: className,
    beaconMajor: beaconMajor,
    beaconSecret: beaconSecret,
    qrSecret: qrSecret,
    activeSession: session?.toEntity(),
  );
}

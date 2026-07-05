// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kiosk_sync_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_KioskSessionDto _$KioskSessionDtoFromJson(Map<String, dynamic> json) =>
    _KioskSessionDto(
      id: json['id'] as String,
      type: json['type'] as String,
      period: (json['period'] as num?)?.toInt(),
    );

Map<String, dynamic> _$KioskSessionDtoToJson(_KioskSessionDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'period': instance.period,
    };

_KioskSyncDto _$KioskSyncDtoFromJson(Map<String, dynamic> json) =>
    _KioskSyncDto(
      deviceId: json['device_id'] as String,
      classId: json['class_id'] as String,
      className: json['class_name'] as String,
      beaconMajor: (json['beacon_major'] as num).toInt(),
      beaconSecret: json['beacon_secret'] as String,
      qrSecret: json['qr_secret'] as String?,
      session: json['session'] == null
          ? null
          : KioskSessionDto.fromJson(json['session'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$KioskSyncDtoToJson(_KioskSyncDto instance) =>
    <String, dynamic>{
      'device_id': instance.deviceId,
      'class_id': instance.classId,
      'class_name': instance.className,
      'beacon_major': instance.beaconMajor,
      'beacon_secret': instance.beaconSecret,
      'qr_secret': instance.qrSecret,
      'session': instance.session,
    };

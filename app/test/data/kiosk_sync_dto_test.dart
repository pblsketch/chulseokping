import 'package:chulseokping_app/data/models/kiosk_sync_dto.dart';
import 'package:chulseokping_app/domain/value_objects/session_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('KioskSyncDto: 활성 세션 포함 JSON → entity', () {
    final dto = KioskSyncDto.fromJson({
      'device_id': 'd1',
      'class_id': 'c1',
      'class_name': '더미 1학년 1반',
      'beacon_major': 101,
      'beacon_secret': 'aabb',
      'qr_secret': 'ccdd',
      'session': {'id': 's1', 'type': 'PERIOD', 'period': 3},
    });
    final entity = dto.toEntity();
    expect(entity.className, '더미 1학년 1반');
    expect(entity.beaconMajor, 101);
    expect(entity.activeSession?.type, SessionType.period);
    expect(entity.activeSession?.label, '3교시');
  });

  test('KioskSyncDto: 세션 없음(null) → activeSession null', () {
    final dto = KioskSyncDto.fromJson({
      'device_id': 'd1',
      'class_id': 'c1',
      'class_name': '더미 1학년 1반',
      'beacon_major': 101,
      'beacon_secret': 'aabb',
      'qr_secret': null,
      'session': null,
    });
    final entity = dto.toEntity();
    expect(entity.activeSession, isNull);
    expect(entity.qrSecret, isNull);
  });

  test('KioskSession.label: 조회 세션', () {
    final dto = KioskSessionDto.fromJson({
      'id': 's1',
      'type': 'HOMEROOM',
      'period': null,
    });
    expect(dto.toEntity().label, '조회');
  });
}

/// 체크인 방식 5종 (PRD §5 method enum).
enum CheckInMode {
  qr('QR'),
  pin('PIN'),
  ble('BLE'),
  manual('MANUAL'),
  list('LIST');

  const CheckInMode(this.wireName);

  final String wireName;

  static CheckInMode fromWire(String value) =>
      CheckInMode.values.firstWhere((m) => m.wireName == value);
}

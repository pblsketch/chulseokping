import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// PI-3 회귀 가드: entity/model/payload 어디에도 좌표 필드를 두지 않는다.
/// lib/ 전체 Dart 소스를 스캔해 좌표성 식별자가 없음을 고정한다 (ARCHITECTURE §7).
void main() {
  test('lib/ 어디에도 좌표(lat/lng) 식별자가 없다', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue);

    final forbidden = RegExp(
      r'\b(lat|lng|latitude|longitude|geolocation|geoPoint)\b',
      caseSensitive: false,
    );

    final violations = <String>[];
    for (final file in libDir.listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final trimmed = lines[i].trim();
        // 주석은 제외 — 가드의 목적은 코드 식별자(필드/변수/파라미터) 차단이다.
        if (trimmed.startsWith('//')) continue;
        if (forbidden.hasMatch(lines[i])) {
          violations.add('${file.path}:${i + 1}: $trimmed');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: '좌표 저장·전송 금지 (PI-3). 위반:\n${violations.join('\n')}',
    );
  });
}

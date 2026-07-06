import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 회귀 가드: .stream() 실시간 구독은 supabase_realtime publication에
/// 등록된 테이블만 이벤트를 받는다. 등록 마이그레이션이 사라지면
/// 교사 대시보드·학생 홈이 조용히 "초기 1회 조회"로 퇴화한다 (2026-07-06 실기 회귀).
void main() {
  test('마이그레이션에 attendance_logs·sessions realtime 등록이 존재한다', () {
    final dir = Directory('../supabase/migrations');
    final sql = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.sql'))
        .map((f) => f.readAsStringSync())
        .join('\n');

    for (final table in ['attendance_logs', 'sessions']) {
      expect(
        RegExp(
          'alter publication supabase_realtime\\s+add table public\\.$table',
        ).hasMatch(sql),
        isTrue,
        reason:
            '$table이 supabase_realtime publication에 등록되어야 '
            '.stream() 구독(교사 대시보드/학생 홈)이 실시간으로 동작한다',
      );
    }
  });
}

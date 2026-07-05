import 'package:chulseokping_app/data/datasources/supabase_remote_data_source.dart';
import 'package:chulseokping_app/data/models/session_dto.dart';
import 'package:chulseokping_app/data/repositories/session_repository_impl.dart';
import 'package:chulseokping_app/domain/value_objects/session_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements SupabaseRemoteDataSource {}

SessionDto dto(String id, {String status = 'ACTIVE'}) => SessionDto(
  id: id,
  classId: 'c1',
  teacherId: 't1',
  type: 'HOMEROOM',
  date: DateTime(2026, 7, 6),
  mode: 'BYOD',
  status: status,
  startedAt: DateTime(2026, 7, 6, 9),
);

void main() {
  late MockRemote remote;
  late SessionRepositoryImpl repository;

  setUp(() {
    remote = MockRemote();
    repository = SessionRepositoryImpl(remote);
  });

  test('watchActiveSession: DTO 스트림을 entity 스트림으로 매핑하고, '
      '교사가 세션을 종료·재시작하면(새 이벤트) 최신 값으로 갱신된다', () async {
    when(
      () => remote.watchActiveSession('c1'),
    ).thenAnswer((_) => Stream.fromIterable([dto('s1'), dto('s2'), null]));

    final emissions = await repository.watchActiveSession('c1').toList();

    expect(emissions[0]?.id, 's1');
    expect(emissions[0]?.type, SessionType.homeroom);
    expect(
      emissions[1]?.id,
      's2',
      reason: '재시작된 새 세션으로 자동 갱신되어야 함 (예전 버그: 1회성 조회라 s1에 고정됨)',
    );
    expect(emissions[2], isNull, reason: '세션 종료 후에는 null');
  });
}
